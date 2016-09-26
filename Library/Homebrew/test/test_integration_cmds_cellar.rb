require "integration_cmds_tests"

class IntegrationCommandTestCellar < IntegrationCommandTests
  def test_cellar
    assert_equal HOMEBREW_CELLAR.to_s,
                 cmd("--cellar")
  end
end
