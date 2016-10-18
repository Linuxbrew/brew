require "helper/integration_command_test_case"

class IntegrationCommandTestVersion < IntegrationCommandTestCase
  def test_version
    assert_match HOMEBREW_VERSION.to_s,
                 cmd("--version")
  end
end
