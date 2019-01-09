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
  end
end
