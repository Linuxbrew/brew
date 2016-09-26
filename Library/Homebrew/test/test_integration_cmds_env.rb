require "integration_cmds_tests"

class IntegrationCommandTestEnv < IntegrationCommandTests
  def test_env
    assert_match(/CMAKE_PREFIX_PATH="#{Regexp.escape(HOMEBREW_PREFIX)}[:"]/,
                 cmd("--env"))
  end
end
