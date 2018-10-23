require "requirements"

describe Requirements do
  describe "#<<" do
    it "returns itself" do
      expect(subject << Object.new).to be(subject)
    end

    it "merges duplicate requirements" do
      subject << X11Requirement.new << X11Requirement.new
      expect(subject.count).to eq(1)
      subject << Requirement.new
      expect(subject.count).to eq(2)
    end

    it "prefers the larger requirement when merging duplicates" do
      subject << X11Requirement.new << X11Requirement.new(%w[2.6])
      expect(subject.to_a).to eq([X11Requirement.new(%w[2.6])])
    end

    it "does not use the smaller requirement when merging duplicates" do
      subject << X11Requirement.new(%w[2.6]) << X11Requirement.new
      expect(subject.to_a).to eq([X11Requirement.new(%w[2.6])])
    end
  end
end
