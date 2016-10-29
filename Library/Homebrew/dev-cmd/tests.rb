#:  * `tests` [`-v`] [`--coverage`] [`--generic`] [`--no-compat`] [`--only=`<test_script/test_method>] [`--seed` <seed>] [`--trace`] [`--online`] [`--official-cmd-taps`]:
#:    Run Homebrew's unit and integration tests.

require "fileutils"
require "tap"

module Homebrew
  module_function

  def tests
    (HOMEBREW_LIBRARY/"Homebrew").cd do
      ENV.delete "HOMEBREW_VERBOSE"
      ENV.delete "VERBOSE"
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
      end

      Homebrew.install_gem_setup_path! "bundler"
      unless quiet_system("bundle", "check")
        system "bundle", "install"
      end

      # Make it easier to reproduce test runs.
      ENV["SEED"] = ARGV.next if ARGV.include? "--seed"

      files = Dir["test/test_*.rb"]
      files -= Dir["test/test_os_mac_*.rb"] unless OS.mac?

      opts = []
      opts << "--serialize-stdout" if ENV["CI"]

      args = []
      args << "--trace" if ARGV.include? "--trace"

      if ARGV.value("only")
        ENV["HOMEBREW_TESTS_ONLY"] = "1"
        test_name, test_method = ARGV.value("only").split("/", 2)
        files = ["test/test_#{test_name}.rb"]
        args << "--name=test_#{test_method}" if test_method
      end

      args += ARGV.named.select { |v| v[/^TEST(OPTS)?=/] }

      system "bundle", "exec", "parallel_test", *opts,
        "--", *args, "--", *files

      Homebrew.failed = !$?.success?

      if (fs_leak_log = HOMEBREW_LIBRARY/"Homebrew/test/fs_leak_log").file?
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
