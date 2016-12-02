require "testing_env"

class IntegrationCommandTestDoctor < IntegrationCommandTestCase
  def test_doctor
    assert_match "This is an integration test",
                 cmd_fail("doctor", "check_integration_test")
  end
end
