require "compilers"

describe CompilerFailure do
  alias_matcher :fail_with, :be_fails_with

  describe "::create" do
    it "creates a failure when given a symbol" do
      failure = described_class.create(:clang)
      expect(failure).to fail_with(double("Compiler", name: :clang, version: 425))
    end

    it "can be given a build number in a block" do
      failure = described_class.create(:clang) { build 211 }
      expect(failure).to fail_with(double("Compiler", name: :clang, version: 210))
      expect(failure).not_to fail_with(double("Compiler", name: :clang, version: 318))
    end

    it "can be given an empty block" do
      failure = described_class.create(:clang) {}
      expect(failure).to fail_with(double("Compiler", name: :clang, version: 425))
    end

    it "creates a failure when given a hash" do
      failure = described_class.create(gcc: "4.8")
      expect(failure).to fail_with(double("Compiler", name: "gcc-4.8", version: "4.8"))
      expect(failure).to fail_with(double("Compiler", name: "gcc-4.8", version: "4.8.1"))
      expect(failure).not_to fail_with(double("Compiler", name: "gcc-4.7", version: "4.7"))
    end

    it "creates a failure when given a hash and a block with aversion" do
      failure = described_class.create(gcc: "4.8") { version "4.8.1" }
      expect(failure).to fail_with(double("Compiler", name: "gcc-4.8", version: "4.8"))
      expect(failure).to fail_with(double("Compiler", name: "gcc-4.8", version: "4.8.1"))
      expect(failure).not_to fail_with(double("Compiler", name: "gcc-4.8", version: "4.8.2"))
    end
  end
end
