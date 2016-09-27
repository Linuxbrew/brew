require "helper/integration_command_test_case"

class IntegrationCommandTestCacheFormula < IntegrationCommandTestCase
  def test_cache_formula
    assert_match %r{#{HOMEBREW_CACHE}/testball-},
                 cmd("--cache", testball)
  end
end
