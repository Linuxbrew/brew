require "testing_env"
require "dev-cmd/test-bot"

class TestbotCommandTests < Homebrew::TestCase
  def test_resolve_test_tap
    tap = Homebrew.resolve_test_tap
    assert_nil tap, "Should return nil if no tap slug provided"

    slug = "spam/homebrew-eggs"
    url = "https://github.com/#{slug}.git"
    environments = [
      { "TRAVIS_REPO_SLUG" => slug },
      { "UPSTREAM_BOT_PARAMS" => "--tap=#{slug}" },
      { "UPSTREAM_BOT_PARAMS" => "--tap=spam/eggs" },
      { "UPSTREAM_GIT_URL" => url },
      { "GIT_URL" => url },
    ]

    predicate = proc do |message|
      tap = Homebrew.resolve_test_tap
      assert_kind_of Tap, tap, message
      assert_equal tap.user, "spam", message
      assert_equal tap.repo, "eggs", message
    end

    environments.each do |pair|
      with_environment(pair) do
        predicate.call pair.to_s
      end
    end

    ARGV.expects(:value).with("tap").returns(slug)
    predicate.call "ARGV"
  end
end
