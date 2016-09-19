#!/usr/bin/env ruby

SimpleCov.start do
  coverage_dir File.expand_path("../coverage", File.realpath(__FILE__))
  root File.expand_path("../..", File.realpath(__FILE__))

  # We manage the result cache ourselves and the default of 10 minutes can be
  # too low (particularly on Travis CI), causing results from some integration
  # tests to be dropped. This causes random fluctuations in test coverage.
  merge_timeout 86400

  add_filter "/Homebrew/cask/spec/"
  add_filter "/Homebrew/cask/test/"
  add_filter "/Homebrew/compat/"
  add_filter "/Homebrew/test/"
  add_filter "/Homebrew/vendor/"

  if ENV["HOMEBREW_INTEGRATION_TEST"]
    command_name ENV["HOMEBREW_INTEGRATION_TEST"]
    at_exit do
      exit_code = $!.nil? ? 0 : $!.status
      $stdout.reopen("/dev/null")
      SimpleCov.result # Just save result, but don't write formatted output.
      exit! exit_code
    end
  else
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
