require "integration_cmds_tests"

class IntegrationCommandTestEnvCsh < IntegrationCommandTests
  def test_env_csh
    assert_match(/setenv CMAKE_PREFIX_PATH #{Regexp.quote(HOMEBREW_PREFIX.to_s)};/,
                 cmd("--env", "--shell=tcsh"))
  end
end
