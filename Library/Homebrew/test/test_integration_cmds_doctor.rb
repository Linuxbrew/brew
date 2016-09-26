require "integration_cmds_tests"

class IntegrationCommandTestDoctor < IntegrationCommandTests
  def test_doctor
    assert_match "This is an integration test",
                 cmd_fail("doctor", "check_integration_test")
  end
end
