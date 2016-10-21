require "helper/integration_command_test_case"

class IntegrationCommandTestSwitch < IntegrationCommandTestCase
  def test_switch
    assert_match "Usage: brew switch <name> <version>", cmd_fail("switch")
    assert_match "testball not found", cmd_fail("switch", "testball", "0.1")

    setup_test_formula "testball", <<-EOS.undent
      keg_only "just because"
    EOS

    cmd("install", "testball")
    testball_rack = HOMEBREW_CELLAR/"testball"
    FileUtils.cp_r testball_rack/"0.1", testball_rack/"0.2"

    cmd("switch", "testball", "0.2")
    assert_match "testball does not have a version \"0.3\"",
      cmd_fail("switch", "testball", "0.3")
  end
end
