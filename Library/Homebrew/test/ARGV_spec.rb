require "extend/ARGV"

describe HomebrewArgvExtension do
  subject { argv.extend(described_class) }

  let(:argv) { ["mxcl"] }

  describe "#formulae" do
    it "raises an error when a Formula is unavailable" do
      expect { subject.formulae }.to raise_error FormulaUnavailableError
    end

    context "when there are no Formulae" do
      let(:argv) { [] }

      it "returns an empty array" do
        expect(subject.formulae).to be_empty
      end
    end
  end

  describe "#casks" do
    it "returns an empty array if there is no match" do
      expect(subject.casks).to eq []
    end
  end

  describe "#kegs" do
    context "when there are matching Kegs" do
      before do
        keg = HOMEBREW_CELLAR + "mxcl/10.0"
        keg.mkpath
      end

      it "returns an array of Kegs" do
        expect(subject.kegs.length).to eq 1
      end
    end

    context "when there are no matching Kegs" do
      let(:argv) { [] }

      it "returns an empty array" do
        expect(subject.kegs).to be_empty
      end
    end
  end

  describe "#named" do
    let(:argv) { ["foo", "--debug", "-v"] }

    it "returns an array of non-option arguments" do
      expect(subject.named).to eq ["foo"]
    end

    context "when there are no named arguments" do
      let(:argv) { [] }

      it "returns an empty array" do
        expect(subject.named).to be_empty
      end
    end
  end

  describe "#options_only" do
    let(:argv) { ["--foo", "-vds", "a", "b", "cdefg"] }

    it "returns an array of option arguments" do
      expect(subject.options_only).to eq ["--foo", "-vds"]
    end
  end

  describe "#flags_only" do
    let(:argv) { ["--foo", "-vds", "a", "b", "cdefg"] }

    it "returns an array of flags" do
      expect(subject.flags_only).to eq ["--foo"]
    end
  end

  describe "#empty?" do
    let(:argv) { [] }

    it "returns true if it is empty" do
      expect(subject).to be_empty
    end
  end

  describe "#switch?" do
    let(:argv) { ["-ns", "-i", "--bar", "-a-bad-arg"] }

    it "returns true if the given string is a switch" do
      %w[n s i].each do |s|
        expect(subject.switch?(s)).to be true
      end
    end

    it "returns false if the given string is not a switch" do
      %w[b ns bar --bar -n a bad arg].each do |s|
        expect(subject.switch?(s)).to be false
      end
    end
  end

  describe "#flag?" do
    let(:argv) { ["--foo", "-bq", "--bar"] }

    it "returns true if the given string is a flag" do
      expect(subject.flag?("--foo")).to eq true
      expect(subject.flag?("--bar")).to eq true
    end

    it "returns true if there is a switch with the same initial character" do
      expect(subject.flag?("--baz")).to eq true
      expect(subject.flag?("--qux")).to eq true
    end

    it "returns false if there is no matching flag" do
      expect(subject.flag?("--frotz")).to eq false
      expect(subject.flag?("--debug")).to eq false
    end
  end

  describe "#value" do
    let(:argv) { ["--foo=", "--bar=ab"] }

    it "returns the value for a given string" do
      expect(subject.value("foo")).to eq ""
      expect(subject.value("bar")).to eq "ab"
    end

    it "returns nil if there is no matching argument" do
      expect(subject.value("baz")).to be nil
    end
  end

  describe "#values" do
    let(:argv) { ["--foo=", "--bar=a", "--baz=b,c"] }

    it "returns the value for a given argument" do
      expect(subject.values("foo")).to eq []
      expect(subject.values("bar")).to eq ["a"]
      expect(subject.values("baz")).to eq ["b", "c"]
    end

    it "returns nil if there is no matching argument" do
      expect(subject.values("qux")).to be nil
    end
  end
end
