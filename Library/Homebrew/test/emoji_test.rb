require "testing_env"
require "emoji"

class EmojiTest < Homebrew::TestCase
  def test_install_badge
    assert_equal "🍺", Emoji.install_badge

    ENV["HOMEBREW_INSTALL_BADGE"] = "foo"
    assert_equal "foo", Emoji.install_badge
  end
end
