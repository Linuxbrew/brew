require "integration_cmds_tests"

class IntegrationCommandTestVersion < IntegrationCommandTests
  def test_version
    assert_match HOMEBREW_VERSION.to_s,
                 cmd("--version")
  end
end
