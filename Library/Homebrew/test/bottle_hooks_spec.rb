require "formula_installer"
require "hooks/bottles"

describe Homebrew::Hooks::Bottles do
  alias_matcher :pour_bottle, :be_pour_bottle

  subject { FormulaInstaller.new formula }

  let(:formula) do
    double(
      bottle: nil,
      local_bottle_path: nil,
      bottle_disabled?: false,
      some_random_method: true,
      keg_only?: false,
    )
  end

  after(:each) do
    described_class.reset_hooks
  end

  describe "#setup_formula_has_bottle" do
    context "given a block which evaluates to true" do
      before(:each) do
        described_class.setup_formula_has_bottle(&:some_random_method)
      end

      it { is_expected.to pour_bottle }
    end

    context "given a block which evaluates to false" do
      before(:each) do
        described_class.setup_formula_has_bottle { |f| !f.some_random_method }
      end

      it { is_expected.not_to pour_bottle }
    end
  end

  describe "#setup_pour_formula_bottle" do
    before(:each) do
      described_class.setup_formula_has_bottle { true }
      described_class.setup_pour_formula_bottle(&:some_random_method)
    end

    it "does not raise an error" do
      expect { subject.pour }.not_to raise_error
    end
  end
end
