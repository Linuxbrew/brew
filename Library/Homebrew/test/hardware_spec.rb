require "hardware"

module Hardware
  describe CPU do
    describe "::type" do
      it "returns the current CPU's type as a symbol, or :dunno if it cannot be detected" do
        expect(
          [
            :intel,
            :ppc,
            :dunno,
          ],
        ).to include(described_class.type)
      end
    end

    describe "::family" do
      it "returns the current CPU's family name as a symbol, or :dunno if it cannot be detected" do
        skip "Needs an Intel CPU." unless described_class.intel?

        expect(
          [
            :core,
            :core2,
            :penryn,
            :nehalem,
            :arrandale,
            :sandybridge,
            :ivybridge,
            :haswell,
            :broadwell,
            :skylake,
            :kabylake,
            :dunno,
          ],
        ).to include(described_class.family)
      end
    end

    describe "::can_run?" do
      it "reports that Intel machines can run Intel executables" do
        allow(Hardware::CPU).to receive(:type).and_return :intel
        allow(Hardware::CPU).to receive(:bits).and_return 64
        expect(Hardware::CPU.can_run?(:i386)).to be true
        expect(Hardware::CPU.can_run?(:x86_64)).to be true
      end

      it "reports that PowerPC machines can run PowerPC executables" do
        allow(Hardware::CPU).to receive(:type).and_return :ppc
        allow(Hardware::CPU).to receive(:bits).and_return 64
        expect(Hardware::CPU.can_run?(:ppc)).to be true
        expect(Hardware::CPU.can_run?(:ppc64)).to be true
      end

      it "reports that 32-bit Intel machines can't run x86_64 executables" do
        allow(Hardware::CPU).to receive(:type).and_return :intel
        allow(Hardware::CPU).to receive(:bits).and_return 32
        expect(Hardware::CPU.can_run?(:x86_64)).to be false
      end

      it "reports that 32-bit PowerPC machines can't run ppc64 executables" do
        allow(Hardware::CPU).to receive(:type).and_return :ppc
        allow(Hardware::CPU).to receive(:bits).and_return 32
        expect(Hardware::CPU.can_run?(:ppc64)).to be false
      end

      it "identifies that Intel and PowerPC machines can't run each others' executables" do
        allow(Hardware::CPU).to receive(:type).and_return :ppc
        expect(Hardware::CPU.can_run?(:i386)).to be false
        expect(Hardware::CPU.can_run?(:x86_64)).to be false

        allow(Hardware::CPU).to receive(:type).and_return :intel
        expect(Hardware::CPU.can_run?(:ppc)).to be false
        expect(Hardware::CPU.can_run?(:ppc64)).to be false
      end

      it "returns false for unknown CPU types" do
        allow(Hardware::CPU).to receive(:type).and_return :dunno
        expect(Hardware::CPU.can_run?(:i386)).to be false
      end

      it "returns false for unknown arches" do
        expect(Hardware::CPU.can_run?(:blah)).to be false
      end
    end
  end
end
