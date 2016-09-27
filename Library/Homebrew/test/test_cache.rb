require "helper/integration_command_test_case"

class IntegrationCommandTestCache < IntegrationCommandTestCase
  def test_cache
    assert_equal HOMEBREW_CACHE.to_s,
                 cmd("--cache")
  end
end
