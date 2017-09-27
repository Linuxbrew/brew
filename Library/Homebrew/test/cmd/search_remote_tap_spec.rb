require "cmd/search"

describe Homebrew do
  specify "#search_taps" do
    # Otherwise the tested method returns [], regardless of our stub
    ENV.delete("HOMEBREW_NO_GITHUB_API")

    json_response = {
      "items" => [
        {
          "path" => "Formula/some-formula.rb",
          "repository" => {
            "full_name" => "Homebrew/homebrew-foo",
          },
        },
      ],
    }

    allow(GitHub).to receive(:open).and_yield(json_response)

    expect(described_class.search_taps("some-formula"))
      .to match(["homebrew/foo/some-formula"])
  end
end
