require "utils/formatter"
require "utils/tty"

describe Formatter do
  describe "::columns" do
    let(:input) {
      [
        "aa",
        "bbb",
        "ccc",
        "dd",
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
        "dd\n"
      )
    end

    describe "$stdout is a TTY" do
      it "outputs columns" do
        allow_any_instance_of(IO).to receive(:tty?).and_return(true)
        allow(Tty).to receive(:width).and_return(10)

        expect(subject).to eq(
          "aa    ccc\n" \
          "bbb   dd\n"
        )
      end

      it "outputs only one line if everything fits" do
        allow_any_instance_of(IO).to receive(:tty?).and_return(true)
        allow(Tty).to receive(:width).and_return(20)

        expect(subject).to eq(
          "aa   bbb  ccc  dd\n"
        )
      end
    end

    describe "with empty input" do
      let(:input) { [] }

      it { is_expected.to eq("\n") }
    end
  end
end
