require "requirements/x11_requirement"

describe X11Requirement do
  let(:default_name) { "x11" }

  describe "#name" do
    it "defaults to x11" do
      expect(subject.name).to eq(default_name)
    end
  end

  describe "#eql?" do
    it "returns true if the names are equal" do
      other = described_class.new(default_name)
      expect(subject).to eql(other)
    end

    it "and returns false if the names differ" do
      other = described_class.new("foo")
      expect(subject).not_to eql(other)
    end

    it "returns false if the minimum version differs" do
      other = described_class.new(default_name, ["2.5"])
      expect(subject).not_to eql(other)
    end
  end

  describe "#modify_build_environment" do
    it "calls ENV#x11" do
      allow(subject).to receive(:satisfied?).and_return(true)
      expect(ENV).to receive(:x11)
      subject.modify_build_environment
    end
  end
end
