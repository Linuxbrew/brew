require "hardware"

describe Hardware::CPU do
  describe "::type" do
    let(:cpu_types) {
      [
        :intel,
        :ppc,
        :dunno,
      ]
    }

    it "returns the current CPU's type as a symbol, or :dunno if it cannot be detected" do
      expect(cpu_types).to include(described_class.type)
    end
  end

  describe "::family" do
    let(:cpu_families) {
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
      ]
    }

    it "returns the current CPU's family name as a symbol, or :dunno if it cannot be detected" do
      expect(cpu_families).to include described_class.family
    end
  end

  describe "::can_run?" do
    subject { described_class }

    matcher :be_able_to_run do |arch|
      match do |expected|
        allow(expected).to receive(:type).and_return type
        allow(expected).to receive(:bits).and_return bits

        expect(expected.can_run?(arch)).to be true
      end
    end

    let(:type) { described_class.type }
    let(:bits) { described_class.bits }

    before do
      allow(described_class).to receive(:type).and_return type
      allow(described_class).to receive(:bits).and_return bits
    end

    context "when on an 32-bit Intel machine" do
      let(:type) { :intel }
      let(:bits) { 32 }

      it { is_expected.to be_able_to_run :i386 }
      it { is_expected.not_to be_able_to_run :x86_64 }
      it { is_expected.not_to be_able_to_run :ppc32 }
      it { is_expected.not_to be_able_to_run :ppc64 }
    end

    context "when on an 64-bit Intel machine" do
      let(:type) { :intel }
      let(:bits) { 64 }

      it { is_expected.to be_able_to_run :i386 }
      it { is_expected.to be_able_to_run :x86_64 }
      it { is_expected.not_to be_able_to_run :ppc32 }
      it { is_expected.not_to be_able_to_run :ppc64 }
    end

    context "when on a 32-bit PowerPC machine" do
      let(:type) { :ppc }
      let(:bits) { 32 }

      it { is_expected.not_to be_able_to_run :i386 }
      it { is_expected.not_to be_able_to_run :x86_64 }
      it { is_expected.to be_able_to_run :ppc32 }
      it { is_expected.not_to be_able_to_run :ppc64 }
    end

    context "when on a 64-bit PowerPC machine" do
      let(:type) { :ppc }
      let(:bits) { 64 }

      it { is_expected.not_to be_able_to_run :i386 }
      it { is_expected.not_to be_able_to_run :x86_64 }
      it { is_expected.to be_able_to_run :ppc32 }
      it { is_expected.to be_able_to_run :ppc64 }
    end

    context "when the CPU type is unknown" do
      let(:type) { :dunno }

      it { is_expected.not_to be_able_to_run :i386 }
      it { is_expected.not_to be_able_to_run :x86_64 }
      it { is_expected.not_to be_able_to_run :ppc32 }
      it { is_expected.not_to be_able_to_run :ppc64 }
    end

    context "when the architecture is unknown" do
      it { is_expected.not_to be_able_to_run :blah }
    end
  end
end
