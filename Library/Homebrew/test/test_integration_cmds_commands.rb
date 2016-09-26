require "integration_cmds_tests"

class IntegrationCommandTestCommands < IntegrationCommandTests
  def test_commands
    assert_match "Built-in commands",
                 cmd("commands")
  end
end
