require "integration_cmds_tests"

class IntegrationCommandTestPrefixFormula < IntegrationCommandTests
  def test_prefix_formula
    assert_match "#{HOMEBREW_CELLAR}/testball",
                 cmd("--prefix", testball)
  end
end
