require "requirements/macos_requirement"

describe MacOSRequirement do
  subject(:requirement) { described_class.new }

  describe "#satisfied?" do
    it "returns true on macOS" do
      expect(requirement.satisfied?).to eq(OS.mac?)
    end
  end
end
