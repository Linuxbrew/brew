require "testing_env"

class IntegrationCommandTestVersion < IntegrationCommandTestCase
  def test_version
    assert_match HOMEBREW_VERSION.to_s,
                 cmd("--version")
  end
end
