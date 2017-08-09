require "utils/formatter"
require "utils/tty"

describe Formatter do
  describe "::columns" do
    let(:input) {
      %w[
        aa
        bbb
        ccc
        dd
      ]
    }
    subject { described_class.columns(input) }

    it "doesn't output columns if $stdout is not a TTY." do
      allow_any_instance_of(IO).to receive(:tty?).and_return(false)
      allow(Tty).to receive(:width).and_return(10)

      expect(subject).to eq(
        "aa\n" \
        "bbb\n" \
        "ccc\n" \
        "dd\n",
      )
    end

    describe "$stdout is a TTY" do
      it "outputs columns" do
        allow_any_instance_of(IO).to receive(:tty?).and_return(true)
        allow(Tty).to receive(:width).and_return(10)

        expect(subject).to eq(
          "aa    ccc\n" \
          "bbb   dd\n",
        )
      end

      it "outputs only one line if everything fits" do
        allow_any_instance_of(IO).to receive(:tty?).and_return(true)
        allow(Tty).to receive(:width).and_return(20)

        expect(subject).to eq(
          "aa   bbb  ccc  dd\n",
        )
      end
    end

    describe "with empty input" do
      let(:input) { [] }

      it { is_expected.to eq("\n") }
    end
  end

  describe "::pluralize" do
    it "pluralizes words" do
      expect(described_class.pluralize(0, "cask")).to eq("0 casks")
      expect(described_class.pluralize(1, "cask")).to eq("1 cask")
      expect(described_class.pluralize(2, "cask")).to eq("2 casks")
    end

    it "allows specifying custom plural forms" do
      expect(described_class.pluralize(1, "child", "children")).to eq("1 child")
      expect(described_class.pluralize(2, "child", "children")).to eq("2 children")
    end

    it "has plural forms of Homebrew jargon" do
      expect(described_class.pluralize(1, "formula")).to eq("1 formula")
      expect(described_class.pluralize(2, "formula")).to eq("2 formulae")
    end

    it "pluralizes the last word of a string" do
      expect(described_class.pluralize(1, "new formula")).to eq("1 new formula")
      expect(described_class.pluralize(2, "new formula")).to eq("2 new formulae")
    end
  end
end
