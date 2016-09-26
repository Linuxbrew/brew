require "integration_cmds_tests"

class IntegrationCommandTestCommand < IntegrationCommandTests
  def test_command
    assert_equal "#{HOMEBREW_LIBRARY_PATH}/cmd/info.rb",
                 cmd("command", "info")

    assert_match "Unknown command",
                 cmd_fail("command", "I-don't-exist")
  end
end
