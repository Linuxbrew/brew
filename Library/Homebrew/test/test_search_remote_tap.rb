require "testing_env"
require "cmd/search"

class SearchRemoteTapTests < Homebrew::TestCase
  def test_search_remote_tap
    json_response = {
      "tree" => [
        {
          "path" => "Formula/not-a-formula.rb",
          "type" => "blob",
        },
      ],
    }

    GitHub.stubs(:open).yields(json_response)

    assert_equal ["homebrew/not-a-tap/not-a-formula"], Homebrew.search_tap("homebrew", "not-a-tap", "not-a-formula")
  end
end
