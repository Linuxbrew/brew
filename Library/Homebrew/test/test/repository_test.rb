require "helper/integration_command_test_case"

class IntegrationCommandTestRepository < IntegrationCommandTestCase
  def test_repository
    assert_match HOMEBREW_REPOSITORY.to_s,
                 cmd("--repository")
    assert_match "#{HOMEBREW_LIBRARY}/Taps/foo/homebrew-bar",
                 cmd("--repository", "foo/bar")
  end
end
