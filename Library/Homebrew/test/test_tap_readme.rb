require "helper/integration_command_test_case"

class IntegrationCommandTestTapReadme < IntegrationCommandTestCase
  def test_tap_readme
    assert_match "brew install homebrew/foo/<formula>",
                 cmd("tap-readme", "foo", "--verbose")
    readme = HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo/README.md"
    assert readme.exist?, "The README should be created"
  end
end
