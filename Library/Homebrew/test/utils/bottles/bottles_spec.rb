require "utils/bottles"

describe Utils::Bottles do
  describe "#tag", :needs_macos do
    it "returns :tiger_foo on Tiger PowerPC" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.4"))
      allow(Hardware::CPU).to receive(:type).and_return(:ppc)
      allow(Hardware::CPU).to receive(:family).and_return(:foo)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(false)
      expect(described_class.tag).to eq(:tiger_foo)
    end

    it "returns :tiger on Tiger Intel" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.4"))
      allow(Hardware::CPU).to receive(:type).and_return(:intel)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(false)
      expect(described_class.tag).to eq(:tiger)
    end

    it "returns :tiger_g5_64 on Tiger PowerPC 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.4"))
      allow(Hardware::CPU).to receive(:type).and_return(:ppc)
      allow(Hardware::CPU).to receive(:family).and_return(:g5)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(true)
      expect(described_class.tag).to eq(:tiger_g5_64)
    end

    # Note that this will probably never be used
    it "returns :tiger_64 on Tiger Intel 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.4"))
      allow(Hardware::CPU).to receive(:type).and_return(:intel)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(true)
      expect(described_class.tag).to eq(:tiger_64)
    end

    it "returns :leopard on Leopard Intel" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.5"))
      allow(Hardware::CPU).to receive(:type).and_return(:intel)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(false)
      expect(described_class.tag).to eq(:leopard)
    end

    it "returns :leopard_g5_64 on Leopard PowerPC 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.5"))
      allow(Hardware::CPU).to receive(:type).and_return(:ppc)
      allow(Hardware::CPU).to receive(:family).and_return(:g5)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(true)
      expect(described_class.tag).to eq(:leopard_g5_64)
    end

    it "returns :leopard_64 on Leopard Intel 64-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.5"))
      allow(Hardware::CPU).to receive(:type).and_return(:intel)
      allow(MacOS).to receive(:prefer_64_bit?).and_return(true)
      expect(described_class.tag).to eq(:leopard_64)
    end

    it "returns :snow_leopard_32 on Snow Leopard 32-bit" do
      allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.6"))
      allow(Hardware::CPU).to receive(:is_64_bit?).and_return(false)
      expect(described_class.tag).to eq(:snow_leopard_32)
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
