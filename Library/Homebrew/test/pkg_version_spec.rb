require "pkg_version"

describe PkgVersion do
  describe "::parse" do
    it "parses versions from a string" do
      expect(described_class.parse("1.0_1")).to eq(described_class.new(Version.create("1.0"), 1))
      expect(described_class.parse("1.0_1")).to eq(described_class.new(Version.create("1.0"), 1))
      expect(described_class.parse("1.0")).to eq(described_class.new(Version.create("1.0"), 0))
      expect(described_class.parse("1.0_0")).to eq(described_class.new(Version.create("1.0"), 0))
      expect(described_class.parse("2.1.4_0")).to eq(described_class.new(Version.create("2.1.4"), 0))
      expect(described_class.parse("1.0.1e_1")).to eq(described_class.new(Version.create("1.0.1e"), 1))
    end
  end

  specify "#==" do
    expect(described_class.parse("1.0_0")).to be == described_class.parse("1.0")
    expect(described_class.parse("1.0_1")).to be == described_class.parse("1.0_1")
  end

  describe "#>" do
    it "returns true if the left version is bigger than the right" do
      expect(described_class.parse("1.1")).to be > described_class.parse("1.0_1")
    end

    it "returns true if the left version is HEAD" do
      expect(described_class.parse("HEAD")).to be > described_class.parse("1.0")
    end

    it "raises an error if the other side isn't of the same class" do
      expect {
        described_class.new(Version.create("1.0"), 0) > Object.new
      }.to raise_error(ArgumentError)
    end

    it "is not compatible with Version" do
      expect {
        described_class.new(Version.create("1.0"), 0) > Version.create("1.0")
      }.to raise_error(ArgumentError)
    end
  end

  describe "#<" do
    it "returns true if the left version is smaller than the right" do
      expect(described_class.parse("1.0_1")).to be < described_class.parse("2.0_1")
    end

    it "returns true if the right version is HEAD" do
      expect(described_class.parse("1.0")).to be < described_class.parse("HEAD")
    end
  end

  describe "#<=>" do
    it "returns nil if the comparison fails" do
      expect(described_class.new(Version.create("1.0"), 0) <=> Object.new).to be nil
    end
  end

  describe "#to_s" do
    it "returns a string of the form 'version_revision'" do
      expect(described_class.new(Version.create("1.0"), 0).to_s).to eq("1.0")
      expect(described_class.new(Version.create("1.0"), 1).to_s).to eq("1.0_1")
      expect(described_class.new(Version.create("1.0"), 0).to_s).to eq("1.0")
      expect(described_class.new(Version.create("1.0"), 0).to_s).to eq("1.0")
      expect(described_class.new(Version.create("HEAD"), 1).to_s).to eq("HEAD_1")
      expect(described_class.new(Version.create("HEAD-ffffff"), 1).to_s).to eq("HEAD-ffffff_1")
    end
  end

  describe "#hash" do
    let(:p1) { described_class.new(Version.create("1.0"), 1) }
    let(:p2) { described_class.new(Version.create("1.0"), 1) }
    let(:p3) { described_class.new(Version.create("1.1"), 1) }
    let(:p4) { described_class.new(Version.create("1.0"), 0) }

    it "returns a hash based on the version and revision" do
      expect(p1.hash).to eq(p2.hash)
      expect(p1.hash).not_to eq(p3.hash)
      expect(p1.hash).not_to eq(p4.hash)
    end
  end
end
