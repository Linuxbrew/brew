require "integration_cmds_tests"

class IntegrationCommandTestCacheFormula < IntegrationCommandTests
  def test_cache_formula
    assert_match %r{#{HOMEBREW_CACHE}/testball-},
                 cmd("--cache", testball)
  end
end
