require "requirements/linux_requirement"
require "requirements/macos_requirement"

describe LinuxRequirement do
  describe "#satisfied?" do
    it "returns true if OS is Linux" do
      expect(subject.satisfied?).to eq(OS.linux?)
    end
  end
end

describe MacOSRequirement do
  describe "#satisfied?" do
    it "returns true if OS is macOS" do
      expect(subject.satisfied?).to eq(OS.mac?)
    end
  end
end
