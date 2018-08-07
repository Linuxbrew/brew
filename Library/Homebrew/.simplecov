#!/usr/bin/env ruby

require "English"

SimpleCov.start do
  coverage_dir File.expand_path("../test/coverage", File.realpath(__FILE__))
  root File.expand_path("..", File.realpath(__FILE__))

  # We manage the result cache ourselves and the default of 10 minutes can be
  # too low (particularly on Travis CI), causing results from some integration
  # tests to be dropped. This causes random fluctuations in test coverage.
  merge_timeout 86400

  if ENV["HOMEBREW_INTEGRATION_TEST"]
    command_name "#{ENV["HOMEBREW_INTEGRATION_TEST"]} (#{$PROCESS_ID})"

    at_exit do
      exit_code = $ERROR_INFO.nil? ? 0 : $ERROR_INFO.status
      $stdout.reopen("/dev/null")

      # Just save result, but don't write formatted output.
      coverage_result = Coverage.result
      SimpleCov.add_not_loaded_files(coverage_result)
      simplecov_result = SimpleCov::Result.new(coverage_result)
      SimpleCov::ResultMerger.store_result(simplecov_result)

      exit! exit_code
    end
  else
    command_name "#{command_name} (#{$PROCESS_ID})"

    subdirs = Dir.chdir(SimpleCov.root) { Dir.glob("*") }
                 .reject { |d| d.end_with?(".rb") || ["test", "vendor"].include?(d) }
                 .map { |d| "#{d}/**/*.rb" }.join(",")

    # Not using this during integration tests makes the tests 4x times faster
    # without changing the coverage.
    track_files "#{SimpleCov.root}/{#{subdirs},*.rb}"
  end

  add_filter %r{^/build.rb$}
  add_filter %r{^/config.rb$}
  add_filter %r{^/constants.rb$}
  add_filter %r{^/postinstall.rb$}
  add_filter %r{^/test.rb$}
  add_filter %r{^/compat/}
  add_filter %r{^/dev-cmd/tests.rb$}
  add_filter %r{^/test/}
  add_filter %r{^/vendor/}

  require "rbconfig"
  host_os = RbConfig::CONFIG["host_os"]
  add_filter %r{/os/mac} if host_os !~ /darwin/
  add_filter %r{/os/linux} if host_os !~ /linux/

  # Add groups and the proper project name to the output.
  project_name "Homebrew"
  add_group "Cask", %r{^/cask/}
  add_group "Commands", [%r{/cmd/}, %r{^/dev-cmd/}]
  add_group "Extensions", %r{^/extend/}
  add_group "OS", [%r{^/extend/os/}, %r{^/os/}]
  add_group "Requirements", %r{^/requirements/}
  add_group "Scripts", [
    %r{^/brew.rb$},
    %r{^/build.rb$},
    %r{^/postinstall.rb$},
    %r{^/test.rb$},
  ]
end
