require "helper/integration_command_test_case"

class IntegrationCommandTestAnalytics < IntegrationCommandTestCase
  def test_analytics
    HOMEBREW_REPOSITORY.cd do
      shutup do
        system "git", "init"
      end
    end

    assert_match "Analytics is disabled (by HOMEBREW_NO_ANALYTICS)",
      cmd("analytics", "HOMEBREW_NO_ANALYTICS" => "1")

    cmd("analytics", "off")
    assert_match "Analytics is disabled",
      cmd("analytics", "HOMEBREW_NO_ANALYTICS" => nil)

    cmd("analytics", "on")
    assert_match "Analytics is enabled", cmd("analytics",
      "HOMEBREW_NO_ANALYTICS" => nil)

    assert_match "Invalid usage", cmd_fail("analytics", "on", "off")
    assert_match "Invalid usage", cmd_fail("analytics", "testball")
    cmd("analytics", "regenerate-uuid")
  end
end
