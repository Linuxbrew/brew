require "utils/bottles"

describe Utils::Bottles::Bintray do
  describe "::package" do
    it "converts a Formula name to a package name" do
      expect(described_class.package("openssl@1.1")).to eq("openssl:1.1")
      expect(described_class.package("gtk+")).to eq("gtkx")
      expect(described_class.package("llvm")).to eq("llvm")
    end
  end

  describe "::repository" do
    it "returns the repository for a given Tap" do
      expect(described_class.repository(Tap.new("homebrew", "bintray-test")))
        .to eq("bottles-bintray-test")
    end
  end
end
