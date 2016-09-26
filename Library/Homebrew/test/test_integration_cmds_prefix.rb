require "integration_cmds_tests"

class IntegrationCommandTestPrefix < IntegrationCommandTests
  def test_prefix
    assert_equal HOMEBREW_PREFIX.to_s,
                 cmd("--prefix")
  end
end
