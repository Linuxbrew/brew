require "integration_cmds_tests"

class IntegrationCommandTestSh < IntegrationCommandTests
  def test_sh
    assert_match "Your shell has been configured",
                 cmd("sh", "SHELL" => which("true"))
  end
end
