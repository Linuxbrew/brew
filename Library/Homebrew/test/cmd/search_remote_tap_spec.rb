require "cmd/search"

describe Homebrew do
  describe "#search_taps" do
    before do
      ENV.delete("HOMEBREW_NO_GITHUB_API")
    end

    it "does not raise if `HOMEBREW_NO_GITHUB_API` is set" do
      ENV["HOMEBREW_NO_GITHUB_API"] = "1"
      expect(described_class.search_taps("some-formula")).to match([[], []])
    end

    it "does not raise if the network fails" do
      allow(GitHub).to receive(:open_api).and_raise(GitHub::Error)

      expect(described_class.search_taps("some-formula"))
        .to match([[], []])
    end

    it "returns Formulae and Casks separately" do
      json_response = {
        "items" => [
          {
            "path" => "Formula/some-formula.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-foo",
            },
          },
          {
            "path" => "Casks/some-cask.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-bar",
            },
          },
        ],
      }

      allow(GitHub).to receive(:open_api).and_yield(json_response)

      expect(described_class.search_taps("some-formula"))
        .to match([["homebrew/foo/some-formula"], ["homebrew/bar/some-cask"]])
    end
  end
end
