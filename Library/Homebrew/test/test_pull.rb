require "helper/integration_command_test_case"

class IntegrationCommandTestPull < IntegrationCommandTestCase
  def test_pull
    skip "Requires network connection" if ENV["HOMEBREW_NO_GITHUB_API"]

    core_tap = CoreTap.new
    core_tap.path.cd do
      shutup do
        system "git", "init"
        system "git", "checkout", "-b", "new-branch"
      end
    end

    assert_match "Testing URLs require `--bottle`!",
      cmd_fail("pull", "https://bot.brew.sh/job/Homebrew\%20Testing/1028/")
    assert_match "Current branch is new-branch",
      cmd_fail("pull", "1")
    assert_match "No changed formulae found to bump",
      cmd_fail("pull", "--bump", "8")
    assert_match "Can only bump one changed formula",
      cmd_fail("pull", "--bump",
        "https://api.github.com/repos/Homebrew/homebrew-core/pulls/122")
    assert_match "Patch failed to apply",
      cmd_fail("pull", "https://github.com/Homebrew/homebrew-core/pull/1")
  end
end
