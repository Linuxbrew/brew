require "integration_cmds_tests"

class IntegrationCommandTestUnlink < IntegrationCommandTests
  def test_unlink
    setup_test_formula "testball"

    cmd("install", "testball")
    assert_match "Would remove", cmd("unlink", "--dry-run", "testball")
  end
end
