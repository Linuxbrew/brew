$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
require "global"
require "formulary"

begin
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
  require "parallel_tests/test/runtime_logger"
  require "mocha/setup"
rescue LoadError
  abort "Run `bundle install` or install the mocha and minitest gems before running the tests"
end

require "test/support/helper/test_case"
require "test/support/helper/integration_command_test_case"
