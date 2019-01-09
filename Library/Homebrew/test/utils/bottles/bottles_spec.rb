require "utils/bottles"

describe Utils::Bottles do
  describe "#tag", :needs_macos do
    it "returns :leopard_64 on Leopard Intel 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.5"))
      allow(Hardware::CPU).to receive(:type).and_return(:intel)
      expect(described_class.tag).to eq(:leopard_64)
    end

    it "returns :snow_leopard on Snow Leopard 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.6"))
      allow(Hardware::CPU).to receive(:is_64_bit?).and_return(true)
      expect(described_class.tag).to eq(:snow_leopard)
    end

    it "returns :lion on Lion" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.7"))
      expect(described_class.tag).to eq(:lion)
    end

    it "returns :mountain_lion on Mountain Lion" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.8"))
      expect(described_class.tag).to eq(:mountain_lion)
    end
  end
end
