require "integration_cmds_tests"

class IntegrationCommandTestOutdated < IntegrationCommandTests
  def test_outdated
    setup_test_formula "testball"
    (HOMEBREW_CELLAR/"testball/0.0.1/foo").mkpath

    assert_equal "testball", cmd("outdated")
  end
end
