require "integration_cmds_tests"

class IntegrationCommandTestCache < IntegrationCommandTests
  def test_cache
    assert_equal HOMEBREW_CACHE.to_s,
                 cmd("--cache")
  end
end
