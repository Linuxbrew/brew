require "integration_cmds_tests"

class IntegrationCommandTestEnvPlain < IntegrationCommandTests
  def test_env_plain
    assert_match(/CMAKE_PREFIX_PATH: #{Regexp.quote(HOMEBREW_PREFIX)}/,
                 cmd("--env", "--plain"))
  end
end
