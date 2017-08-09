require "utils/github"

describe GitHub do
  describe "::search_code", :needs_network do
    it "searches code" do
      results = subject.search_code("repo:Homebrew/brew", "path:/", "filename:readme", "language:markdown")

      expect(results.count).to eq(1)
      expect(results.first["name"]).to eq("README.md")
      expect(results.first["path"]).to eq("README.md")
    end
  end
end
