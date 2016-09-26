require "integration_cmds_tests"

class IntegrationCommandTestCellarFormula < IntegrationCommandTests
  def test_cellar_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--cellar", testball)
  end
end
