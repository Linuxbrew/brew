require "testing_env"

class IntegrationCommandTestCellarFormula < IntegrationCommandTestCase
  def test_cellar_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--cellar", testball)
  end
end
