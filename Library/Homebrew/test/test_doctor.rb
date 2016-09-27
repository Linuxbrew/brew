require "helper/integration_command_test_case"

class IntegrationCommandTestDoctor < IntegrationCommandTestCase
  def test_doctor
    assert_match "This is an integration test",
                 cmd_fail("doctor", "check_integration_test")
  end
end
