require "formula"
require "caveats"

describe Caveats do
  subject { described_class.new(f) }
  let(:f) { formula { url "foo-1.0" } }

  specify "#f" do
    expect(subject.f).to eq(f)
  end

  describe "#empty?" do
    it "returns true if the Formula has no caveats" do
      expect(subject).to be_empty
    end

    it "returns false if the Formula has caveats" do
      f = formula do
        url "foo-1.0"

        def caveats
          "something"
        end
      end

      expect(described_class.new(f)).not_to be_empty
    end
  end
end
