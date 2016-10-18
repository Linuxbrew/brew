require "helper/integration_command_test_case"

class IntegrationCommandTestPullOffline < IntegrationCommandTestCase
  def test_pull_offline
    assert_match "You meant `git pull --rebase`.", cmd_fail("pull", "--rebase")
    assert_match "This command requires at least one argument", cmd_fail("pull")
    assert_match "Not a GitHub pull request or commit",
      cmd_fail("pull", "0")
  end
end
