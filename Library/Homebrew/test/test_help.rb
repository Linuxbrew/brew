require "helper/integration_command_test_case"

class IntegrationCommandTestHelp < IntegrationCommandTestCase
  def test_help
    assert_match "Example usage:\n",
                 cmd_fail # Generic help (empty argument list).
    assert_match "Unknown command: command-that-does-not-exist",
                 cmd_fail("help", "command-that-does-not-exist")
    assert_match(/^brew cat /,
                 cmd_fail("cat")) # Missing formula argument triggers help.

    assert_match "Example usage:\n",
                 cmd("help") # Generic help.
    assert_match(/^brew cat /,
                 cmd("help", "cat")) # Internal command (documented, Ruby).
    assert_match(/^brew update /,
                 cmd("help", "update")) # Internal command (documented, Shell).
    assert_match(/^brew update-test /,
                 cmd("help", "update-test")) # Internal developer command (documented, Ruby).
  end
end
