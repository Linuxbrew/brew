require "testing_env"

class IntegrationCommandTestCacheFormula < IntegrationCommandTestCase
  def test_cache_formula
    assert_match %r{#{HOMEBREW_CACHE}/testball-},
                 cmd("--cache", testball)
  end
end
