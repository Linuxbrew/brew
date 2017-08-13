require "utils/github"

describe GitHub do
  describe "::search_code", :needs_network do
    it "queries GitHub code with the passed paramaters" do
      results = subject.search_code(repo: "Homebrew/brew", path: "/",
                                    filename: "readme", language: "markdown")

      expect(results.count).to eq(1)
      expect(results.first["name"]).to eq("README.md")
      expect(results.first["path"]).to eq("README.md")
    end
  end

  describe "::query_string" do
    it "builds a query with the given hash parameters formatted as key:value" do
      query = subject.query_string(user: "Homebrew", repo: "Brew")
      expect(query).to eq("q=user%3aHomebrew+repo%3aTest&per_page=100")
    end

    it "adds a variable number of top-level string parameters to the query when provided" do
      query = subject.query_string("value1", "value2", user: "Homebrew")
      expect(query).to eq("q=value1+value2+user%3aHomebrew&per_page=100")
    end

    it "turns array values into multiple key:value parameters" do
      query = subject.query_string(user: ["Homebrew", "caskroom"])
      expect(query).to eq("q=user%3aHomebrew+user%3acaskroom&per_page=100")
    end
  end
end
