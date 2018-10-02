require "utils/user"

describe User do
  subject { described_class.current }

  it { is_expected.to eq ENV["USER"] }

  describe "#gui?" do
    before do
      allow(SystemCommand).to receive(:run).with("who")
        .and_return([who_output, "", instance_double(Process::Status, success?: true)])
    end

    context "when the current user is in a console session" do
      let(:who_output) {
        <<~EOS
          #{ENV["USER"]}   console  Oct  1 11:23
          #{ENV["USER"]}   ttys001  Oct  1 11:25
        EOS
      }

      its(:gui?) { is_expected.to be true }
    end

    context "when the current user is not in a console session" do
      let(:who_output) {
        <<~EOS
          #{ENV["USER"]}   ttys001  Oct  1 11:25
          fake_user        ttys002  Oct  1 11:27
        EOS
      }

      its(:gui?) { is_expected.to be false }
    end
  end
end
