require "testing_env"
require "test/support/helper/integration_command_test_case"

class IntegrationCommandTestPrefix < IntegrationCommandTestCase
  def test_prefix
    assert_equal HOMEBREW_PREFIX.to_s,
                 cmd("--prefix")
  end
end
