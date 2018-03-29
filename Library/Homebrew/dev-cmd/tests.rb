#:  * `tests` [`--verbose`] [`--coverage`] [`--generic`] [`--no-compat`] [`--only=`<test_script>[`:`<line_number>]] [`--seed=`<seed>] [`--online`] [`--official-cmd-taps`]:
#:    Run Homebrew's unit and integration tests. If provided,
#:    `--only=`<test_script> runs only <test_script>_spec.rb, and `--seed`
#:    randomizes tests with the provided value instead of a random seed.
#:
#:    If `--verbose` (or `-v`) is passed, print the command that runs the tests.
#:
#:    If `--coverage` is passed, also generate code coverage reports.
#:
#:    If `--generic` is passed, only run OS-agnostic tests.
#:
#:    If `--no-compat` is passed, do not load the compatibility layer when
#:    running tests.
#:
#:    If `--online` is passed, include tests that use the GitHub API and tests
#:    that use any of the taps for official external commands.

require "cli_parser"
require "fileutils"
require "tap"

module Homebrew
  module_function

  def tests
    args = Homebrew::CLI::Parser.parse do
      switch "--no-compat"
      switch "--generic"
      switch "-v", "--verbose"
      switch "--coverage"
      switch "--online"
      flag   "--only", required: true
      flag   "--seed", required: true
    end

    HOMEBREW_LIBRARY_PATH.cd do
      ENV.delete("HOMEBREW_VERBOSE")
      ENV.delete("VERBOSE")
      ENV.delete("HOMEBREW_CASK_OPTS")
      ENV.delete("HOMEBREW_TEMP")
      ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
      ENV["HOMEBREW_DEVELOPER"] = "1"
      ENV["HOMEBREW_NO_COMPAT"] = "1" if args.no_compat?
      ENV["HOMEBREW_TEST_GENERIC_OS"] = "1" if args.generic?

      if args.online?
        ENV["HOMEBREW_TEST_ONLINE"] = "1"
      else
        ENV["HOMEBREW_NO_GITHUB_API"] = "1"
      end

      if args.coverage?
        ENV["HOMEBREW_TESTS_COVERAGE"] = "1"
        FileUtils.rm_f "test/coverage/.resultset.json"
      end

      ENV["BUNDLE_GEMFILE"] = "#{HOMEBREW_LIBRARY_PATH}/test/Gemfile"

      # Override author/committer as global settings might be invalid and thus
      # will cause silent failure during the setup of dummy Git repositories.
      %w[AUTHOR COMMITTER].each do |role|
        ENV["GIT_#{role}_NAME"] = "brew tests"
        ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
        ENV["GIT_#{role}_DATE"]  = "Sun Jan 22 19:59:13 2017 +0000"
      end

      Homebrew.install_gem_setup_path! "bundler"
      system "bundle", "install" unless quiet_system("bundle", "check")

      parallel = true

      files = if args.only
        test_name, line = args.only.split(":", 2)

        if line.nil?
          Dir.glob("test/{#{test_name},#{test_name}/**/*}_spec.rb")
        else
          parallel = false
          ["test/#{test_name}_spec.rb:#{line}"]
        end
      else
        Dir.glob("test/**/*_spec.rb").reject { |p| p =~ %r{^test/vendor/bundle/} }
      end

      opts = if ENV["CI"]
        %w[
          --combine-stderr
          --serialize-stdout
        ]
      else
        %w[
          --nice
        ]
      end

      # Generate seed ourselves and output later to avoid multiple different
      # seeds being output when running parallel tests.
      seed = args.seed ? args.seed : rand(0xFFFF).to_i

      args = ["-I", HOMEBREW_LIBRARY_PATH/"test"]
      args += %W[
        --seed #{seed}
        --color
        --require spec_helper
        --format NoSeedProgressFormatter
        --format ParallelTests::RSpec::RuntimeLogger
        --out #{HOMEBREW_CACHE}/tests/parallel_runtime_rspec.log
      ]

      unless OS.mac?
        args << "--tag" << "~needs_macos"
        files = files.reject { |p| p =~ %r{^test/(os/mac|cask)(/.*|_spec\.rb)$} }
      end

      unless OS.linux?
        files = files.reject { |p| p =~ %r{^test/os/linux(/.*|_spec\.rb)$} }
      end

      puts "Randomized with seed #{seed}"

      if parallel
        system "bundle", "exec", "parallel_rspec", *opts, "--", *args, "--", *files
      else
        system "bundle", "exec", "rspec", *args, "--", *files
      end

      return if $CHILD_STATUS.success?
      Homebrew.failed = true
    end
  end
end
