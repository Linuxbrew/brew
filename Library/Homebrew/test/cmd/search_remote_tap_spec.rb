require "cmd/search"

describe Homebrew do
  specify "#search_tap" do
    json_response = {
      "tree" => [
        {
          "path" => "Formula/not-a-formula.rb",
          "type" => "blob",
        },
      ],
    }

    allow(GitHub).to receive(:open).and_yield(json_response)

    expect(described_class.search_tap("homebrew", "not-a-tap", "not-a-formula"))
      .to eq(["homebrew/not-a-tap/not-a-formula"])
  end
end
