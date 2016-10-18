require "helper/integration_command_test_case"

class IntegrationCommandTestBundle < IntegrationCommandTestCase
  def test_bundle
    needs_test_cmd_taps
    setup_remote_tap("homebrew/bundle")
    HOMEBREW_REPOSITORY.cd do
      shutup do
        system "git", "init"
        system "git", "commit", "--allow-empty", "-m", "This is a test commit"
      end
    end

    mktmpdir do |path|
      FileUtils.touch "#{path}/Brewfile"
      Dir.chdir path do
        assert_equal "The Brewfile's dependencies are satisfied.",
          cmd("bundle", "check")
      end
    end
  end
end
