begin
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
  require "mocha/setup"
  require "parallel_tests/test/runtime_logger"
  require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
rescue LoadError
  abort "Run `bundle install` before running the tests."
end

$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "global"

require "test/support/helper/test_case"
require "test/support/helper/integration_command_test_case"
