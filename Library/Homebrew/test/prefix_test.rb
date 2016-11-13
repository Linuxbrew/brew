require "testing_env"

class IntegrationCommandTestPrefix < IntegrationCommandTestCase
  def test_prefix
    assert_equal HOMEBREW_PREFIX.to_s,
                 cmd("--prefix")
  end
end
