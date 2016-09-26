require "helper/integration_command_test_case"

class IntegrationCommandTestSh < IntegrationCommandTestCase
  def test_sh
    assert_match "Your shell has been configured",
                 cmd("sh", "SHELL" => which("true"))
  end
end
