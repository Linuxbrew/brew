require "helper/integration_command_test_case"

class IntegrationCommandTestCommand < IntegrationCommandTestCase
  def test_command
    assert_equal "#{HOMEBREW_LIBRARY_PATH}/cmd/info.rb",
                 cmd("command", "info")

    assert_match "Unknown command",
                 cmd_fail("command", "I-don't-exist")
  end
end
