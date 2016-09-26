require "integration_cmds_tests"

class IntegrationCommandTestEnvFish < IntegrationCommandTests
  def test_env_fish
    assert_match(/set [-]gx CMAKE_PREFIX_PATH "#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=fish"))
  end
end
