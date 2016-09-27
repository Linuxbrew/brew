require "helper/integration_command_test_case"

class IntegrationCommandTestConfig < IntegrationCommandTestCase
  def test_config
    assert_match "HOMEBREW_VERSION: #{HOMEBREW_VERSION}",
                 cmd("config")
  end
end
