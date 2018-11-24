require "requirements/java_requirement"

describe JavaRequirement do
  describe "initialize" do
    it "parses '1.8' tag correctly" do
      req = described_class.new(["1.8"])
      expect(req.display_s).to eq("java = 1.8")
    end

    it "parses '9' tag correctly" do
      req = described_class.new(["9"])
      expect(req.display_s).to eq("java = 9")
    end

    it "parses '9+' tag correctly" do
      req = described_class.new(["9+"])
      expect(req.display_s).to eq("java >= 9")
    end

    it "parses '11' tag correctly" do
      req = described_class.new(["11"])
      expect(req.display_s).to eq("java = 11")
    end

    it "parses bogus tag correctly" do
      req = described_class.new(["bogus1.8"])
      expect(req.display_s).to eq("java")
    end
  end
end
