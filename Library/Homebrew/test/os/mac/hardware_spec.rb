require "hardware"
require "extend/os/mac/hardware/cpu"

describe Hardware::CPU do
  describe "::can_run?" do
    it "reports that Intel Macs can run Intel executables" do
      allow(described_class).to receive(:type).and_return :intel
      allow(described_class).to receive(:bits).and_return 64
      expect(described_class.can_run?(:i386)).to be true
      expect(described_class.can_run?(:x86_64)).to be true
    end

    it "reports that PowerPC Macs can run PowerPC executables" do
      allow(described_class).to receive(:type).and_return :ppc
      allow(described_class).to receive(:bits).and_return 64
      expect(described_class.can_run?(:ppc)).to be true
      expect(described_class.can_run?(:ppc64)).to be true
    end

    it "reports that 32-bit Intel Macs can't run x86_64 executables" do
      allow(described_class).to receive(:type).and_return :intel
      allow(described_class).to receive(:bits).and_return 32
      expect(described_class.can_run?(:x86_64)).to be false
    end

    it "reports that 32-bit PowerPC Macs can't run ppc64 executables" do
      allow(described_class).to receive(:type).and_return :ppc
      allow(described_class).to receive(:bits).and_return 32
      expect(described_class.can_run?(:ppc64)).to be false
    end

    it "reports that Intel Macs can only run 32-bit PowerPC executables on 10.6 and older" do
      allow(described_class).to receive(:type).and_return :intel
      allow(OS::Mac).to receive(:version).and_return OS::Mac::Version.new "10.6"
      expect(described_class.can_run?(:ppc)).to be true

      allow(OS::Mac).to receive(:version).and_return OS::Mac::Version.new "10.7"
      expect(described_class.can_run?(:ppc)).to be false
    end

    it "reports that PowerPC Macs can't run Intel executables" do
      allow(described_class).to receive(:type).and_return :ppc
      expect(described_class.can_run?(:i386)).to be false
      expect(described_class.can_run?(:x86_64)).to be false
    end

    it "returns false for unknown CPU types" do
      allow(described_class).to receive(:type).and_return :dunno
      expect(described_class.can_run?(:i386)).to be false
    end

    it "returns false for unknown arches" do
      expect(described_class.can_run?(:blah)).to be false
    end
  end
end
