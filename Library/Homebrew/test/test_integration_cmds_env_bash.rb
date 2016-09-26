require "integration_cmds_tests"

class IntegrationCommandTestEnvBash < IntegrationCommandTests
  def test_env_bash
    assert_match(/export CMAKE_PREFIX_PATH="#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=bash"))
  end
end
