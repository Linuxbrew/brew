$:.unshift File.expand_path("../..", __FILE__)
$:.unshift File.expand_path("../support/lib", __FILE__)

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
require "global"
require "formulary"

# Test environment setup
(HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-core/Formula").mkpath
%w[cache formula_cache locks cellar logs temp].each { |d| HOMEBREW_PREFIX.parent.join(d).mkpath }

begin
  require "minitest/autorun"
  require "parallel_tests/test/runtime_logger"
  require "mocha/setup"
rescue LoadError
  abort "Run `bundle install` or install the mocha and minitest gems before running the tests"
end

require "test/support/helper/test_case"
require "test/support/helper/integration_command_test_case"
