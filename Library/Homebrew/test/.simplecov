# vim: filetype=ruby

SimpleCov.start do
  tests_path = File.dirname(__FILE__)

  minimum_coverage 40 unless ENV["HOMEBREW_TESTS_ONLY"]
  coverage_dir File.expand_path("#{tests_path}/coverage")
  root File.expand_path("#{tests_path}/..")

  # We manage the result cache ourselves and the default of 10 minutes can be
  # too low (particularly on Travis CI), causing results from some integration
  # tests to be dropped. This causes random fluctuations in test coverage.
  merge_timeout 86400

  add_filter "/Homebrew/cask/"
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

# Don't use Coveralls outside of CI, as it will override SimpleCov's default
# formatter causing the `index.html` not to be written once all tests finish.
if RUBY_VERSION.split(".").first.to_i >= 2 && !ENV["HOMEBREW_INTEGRATION_TEST"] && ENV["CI"]
  require "coveralls"
  Coveralls.wear!
end
