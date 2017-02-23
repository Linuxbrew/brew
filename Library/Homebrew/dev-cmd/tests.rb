#:  * `tests` [`-v`] [`--coverage`] [`--generic`] [`--no-compat`] [`--only=`<test_script:test_method>] [`--seed` <seed>] [`--trace`] [`--online`] [`--official-cmd-taps`]:
#:    Run Homebrew's unit and integration tests.

require "fileutils"
require "tap"

module Homebrew
  module_function

  def run_tests(executable, files, args = [])
    opts = []
    opts << "--serialize-stdout" if ENV["CI"]

    system "bundle", "exec", executable, *opts, "--", *args, "--", *files

    return if $?.success?
    Homebrew.failed = true
  end

  def tests
    HOMEBREW_LIBRARY_PATH.cd do
      ENV.delete "HOMEBREW_VERBOSE"
      ENV.delete "VERBOSE"
      ENV.delete("HOMEBREW_CASK_OPTS")
      ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
      ENV["HOMEBREW_DEVELOPER"] = "1"
      ENV["TESTOPTS"] = "-v" if ARGV.verbose?
      ENV["HOMEBREW_NO_COMPAT"] = "1" if ARGV.include? "--no-compat"
      ENV["HOMEBREW_TEST_GENERIC_OS"] = "1" if ARGV.include? "--generic"
      ENV["HOMEBREW_NO_GITHUB_API"] = "1" unless ARGV.include? "--online"
      if ARGV.include? "--official-cmd-taps"
        ENV["HOMEBREW_TEST_OFFICIAL_CMD_TAPS"] = "1"
      end

      if ARGV.include? "--coverage"
        ENV["HOMEBREW_TESTS_COVERAGE"] = "1"
        FileUtils.rm_f "test/coverage/.resultset.json"
      end

      ENV["BUNDLE_GEMFILE"] = "#{HOMEBREW_LIBRARY_PATH}/test/Gemfile"
      ENV["BUNDLE_PATH"] = "#{HOMEBREW_LIBRARY_PATH}/vendor/bundle"

      # Override author/committer as global settings might be invalid and thus
      # will cause silent failure during the setup of dummy Git repositories.
      %w[AUTHOR COMMITTER].each do |role|
        ENV["GIT_#{role}_NAME"] = "brew tests"
        ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
        ENV["GIT_#{role}_DATE"]  = "Sun Jan 22 19:59:13 2017 +0000"
      end

      Homebrew.install_gem_setup_path! "bundler"
      unless quiet_system("bundle", "check")
        system "bundle", "install"
      end

      # Make it easier to reproduce test runs.
      ENV["SEED"] = ARGV.next if ARGV.include? "--seed"

      files = Dir.glob("test/**/*_{spec,test}.rb")
                 .reject { |p| !OS.mac? && p =~ %r{^test/(os/mac|cask)(/.*|_(test|spec)\.rb)$} }

      test_args = []
      test_args << "--trace" if ARGV.include? "--trace"

      if ARGV.value("only")
        test_name, test_method = ARGV.value("only").split(":", 2)
        files = Dir.glob("test/{#{test_name},#{test_name}/**/*}_{spec,test}.rb")
        test_args << "--name=test_#{test_method}" if test_method
      end

      test_files = files.select { |p| p.end_with?("_test.rb") }
      spec_files = files.select { |p| p.end_with?("_spec.rb") }

      test_args += ARGV.named.select { |v| v[/^TEST(OPTS)?=/] }
      run_tests "parallel_test", test_files, test_args

      spec_args = [
        "--color",
        "-I", HOMEBREW_LIBRARY_PATH/"test",
        "--require", "spec_helper",
        "--format", "progress",
        "--format", "ParallelTests::RSpec::RuntimeLogger",
        "--out", "tmp/parallel_runtime_rspec.log"
      ]
      spec_args << "--tag" << "~needs_macos" unless OS.mac?

      run_tests "parallel_rspec", spec_files, spec_args

      if (fs_leak_log = HOMEBREW_LIBRARY_PATH/"tmp/fs_leak.log").file?
        fs_leak_log_content = fs_leak_log.read
        unless fs_leak_log_content.empty?
          opoo "File leak is detected"
          puts fs_leak_log_content
          Homebrew.failed = true
        end
      end
    end
  end
end
