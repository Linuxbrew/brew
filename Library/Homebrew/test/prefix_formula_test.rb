require "testing_env"

class IntegrationCommandTestPrefixFormula < IntegrationCommandTestCase
  def test_prefix_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--prefix", testball)
  end
end
