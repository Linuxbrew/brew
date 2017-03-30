#!/usr/bin/env ruby

require "English"

SimpleCov.start do
  coverage_dir File.expand_path("../test/coverage", File.realpath(__FILE__))
  root File.expand_path("..", File.realpath(__FILE__))

  # We manage the result cache ourselves and the default of 10 minutes can be
  # too low (particularly on Travis CI), causing results from some integration
  # tests to be dropped. This causes random fluctuations in test coverage.
  merge_timeout 86400

  add_filter "/Homebrew/compat/"
  add_filter "/Homebrew/dev-cmd/tests.rb"
  add_filter "/Homebrew/test/"
  add_filter "/Homebrew/vendor/"

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
    # Not using this during integration tests makes the tests 4x times faster
    # without changing the coverage.
    track_files "#{SimpleCov.root}/**/*.rb"
  end

  # Add groups and the proper project name to the output.
  project_name "Homebrew"
  add_group "Cask", "/Homebrew/cask/"
  add_group "Commands", %w[/Homebrew/cmd/ /Homebrew/dev-cmd/]
  add_group "Extensions", "/Homebrew/extend/"
  add_group "OS", %w[/Homebrew/extend/os/ /Homebrew/os/]
  add_group "Requirements", "/Homebrew/requirements/"
  add_group "Scripts", %w[
    /Homebrew/brew.rb
    /Homebrew/build.rb
    /Homebrew/postinstall.rb
    /Homebrew/test.rb
  ]
end
