require "helper/integration_command_test_case"

class IntegrationCommandTestServices < IntegrationCommandTestCase
  def test_services
    needs_test_cmd_taps
    needs_macos
    setup_remote_tap("homebrew/services")
    assert_equal "Warning: No services available to control with `brew services`",
      cmd("services", "list")
  end
end
