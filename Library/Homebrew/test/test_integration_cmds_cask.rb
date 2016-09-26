require "integration_cmds_tests"

class IntegrationCommandTestCask < IntegrationCommandTests
  def test_cask
    needs_test_cmd_taps
    needs_macos
    setup_remote_tap("caskroom/cask")
    cmd("cask", "list")
  end
end
