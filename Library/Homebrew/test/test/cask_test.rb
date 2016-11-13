require "testing_env"

class IntegrationCommandTestCask < IntegrationCommandTestCase
  def test_cask
    needs_test_cmd_taps
    needs_macos
    setup_remote_tap("caskroom/cask")
    cmd("cask", "list", "--caskroom=#{HOMEBREW_PREFIX}/Caskroom")
  end
end
