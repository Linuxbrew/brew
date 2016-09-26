require "integration_cmds_tests"

class IntegrationCommandTestCleanup < IntegrationCommandTests
  def test_cleanup
    (HOMEBREW_CACHE/"test").write "test"
    assert_match "#{HOMEBREW_CACHE}/test", cmd("cleanup", "--prune=all")
  end
end
