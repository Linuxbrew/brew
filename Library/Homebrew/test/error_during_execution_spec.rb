describe ErrorDuringExecution do
  subject(:error) { described_class.new(command, status: status, output: output) }

  let(:command) { ["false"] }
  let(:status) { instance_double(Process::Status, exitstatus: exitstatus) }
  let(:exitstatus) { 1 }
  let(:output) { nil }

  describe "#initialize" do
    it "fails when only given a command" do
      expect {
        described_class.new(command)
      }.to raise_error(ArgumentError)
    end

    it "fails when only given a status" do
      expect {
        described_class.new(status: status)
      }.to raise_error(ArgumentError)
    end

    it "does not raise an error when given both a command and a status" do
      expect {
        described_class.new(command, status: status)
      }.not_to raise_error
    end
  end

  describe "#to_s" do
    context "when only given a command and a status" do
      its(:to_s) { is_expected.to eq "Failure while executing; `false` exited with 1." }
    end

    context "when additionally given the output" do
      let(:output) {
        [
          [:stdout, "This still worked.\n"],
          [:stderr, "Here something went wrong.\n"],
        ]
      }

      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      its(:to_s) {
        expect(subject.to_s).to eq <<~EOS
          Failure while executing; `false` exited with 1. Here's the output:
          This still worked.
          #{Formatter.error("Here something went wrong.\n")}
        EOS
      }
    end

    context "when command arguments contain special characters" do
      let(:command) { ["env", "PATH=/bin", "cat", "with spaces"] }

      its(:to_s) {
        expect(subject.to_s)
          .to eq 'Failure while executing; `env PATH=/bin cat with\ spaces` exited with 1.'
      }
    end
  end
end
