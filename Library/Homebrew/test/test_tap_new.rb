require "helper/integration_command_test_case"

class IntegrationCommandTestTapNew < IntegrationCommandTestCase
  def test_tap_readme
    assert_equal "", cmd("tap-new", "homebrew/foo", "--verbose")
    readme = HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo/README.md"
    assert readme.exist?, "The README should be created"
  end
end
