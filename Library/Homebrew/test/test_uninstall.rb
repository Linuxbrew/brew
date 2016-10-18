require "helper/integration_command_test_case"

class IntegrationCommandTestUninstall < IntegrationCommandTestCase
  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end
end
