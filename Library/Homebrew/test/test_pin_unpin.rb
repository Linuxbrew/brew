require "helper/integration_command_test_case"

class IntegrationCommandTestPinUnpin < IntegrationCommandTestCase
  def test_pin_unpin
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    cmd("pin", "testball")
    cmd("upgrade")
    refute((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should NOT be created")

    cmd("unpin", "testball")
    cmd("upgrade")
    assert((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should be created")
  end
end
