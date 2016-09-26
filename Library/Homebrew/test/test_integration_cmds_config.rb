require "integration_cmds_tests"

class IntegrationCommandTestConfig < IntegrationCommandTests
  def test_config
    assert_match "HOMEBREW_VERSION: #{HOMEBREW_VERSION}",
                 cmd("config")
  end
end
