require "integration_cmds_tests"

class IntegrationCommandTestUninstall < IntegrationCommandTests
  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end
end
