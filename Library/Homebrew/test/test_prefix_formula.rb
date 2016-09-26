require "helper/integration_command_test_case"

class IntegrationCommandTestPrefixFormula < IntegrationCommandTestCase
  def test_prefix_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--prefix", testball)
  end
end
