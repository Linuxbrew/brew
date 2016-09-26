require "integration_cmds_tests"

class IntegrationCommandTestUpgrade < IntegrationCommandTests
  def test_upgrade
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    cmd("upgrade")
    assert((HOMEBREW_CELLAR/"testball/0.1").directory?,
      "The latest version directory should be created")
  end
end
