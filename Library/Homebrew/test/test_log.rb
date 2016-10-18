require "helper/integration_command_test_case"

class IntegrationCommandTestLog < IntegrationCommandTestCase
  def test_log
    FileUtils.cd HOMEBREW_REPOSITORY do
      shutup do
        system "git", "init"
        system "git", "commit", "--allow-empty", "-m", "This is a test commit"
      end
    end
    assert_match "This is a test commit", cmd("log")
  end
end
