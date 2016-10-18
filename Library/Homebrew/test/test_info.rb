require "testing_env"
require "cmd/info"
require "formula"
require "helper/integration_command_test_case"

class IntegrationCommandTestInfo < IntegrationCommandTestCase
  def test_info
    setup_test_formula "testball"

    assert_match "testball: stable 0.1",
                 cmd("info", "testball")
  end
end

class InfoCommandTests < Homebrew::TestCase
  def test_github_remote_path
    remote = "https://github.com/Homebrew/homebrew-core"
    assert_equal "https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb",
      Homebrew.github_remote_path(remote, "Formula/git.rb")
    assert_equal "https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb",
      Homebrew.github_remote_path("#{remote}.git", "Formula/git.rb")

    assert_equal "https://github.com/user/repo/blob/master/foo.rb",
      Homebrew.github_remote_path("git@github.com:user/repo", "foo.rb")

    assert_equal "https://mywebsite.com/foo/bar.rb",
      Homebrew.github_remote_path("https://mywebsite.com", "foo/bar.rb")
  end
end
