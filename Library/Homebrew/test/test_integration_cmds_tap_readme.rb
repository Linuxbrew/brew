require "integration_cmds_tests"

class IntegrationCommandTestTapReadme < IntegrationCommandTests
  def test_tap_readme
    assert_match "brew install homebrew/foo/<formula>",
                 cmd("tap-readme", "foo", "--verbose")
    readme = HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo/README.md"
    assert readme.exist?, "The README should be created"
  end
end
