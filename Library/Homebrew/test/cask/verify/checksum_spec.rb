describe Hbc::Verify::Checksum, :cask do
  let(:cask) { double("cask", token: "cask") }
  let(:downloaded_path) { double("downloaded_path") }
  let(:verification) { described_class.new(cask, downloaded_path) }

  before do
    allow(cask).to receive(:sha256).and_return(sha256)
  end

  describe ".me?" do
    subject { described_class.me?(cask) }

    context "sha256 is :no_check" do
      let(:sha256) { :no_check }

      it { is_expected.to be false }
    end

    context "sha256 is nil" do
      let(:sha256) { nil }

      it { is_expected.to be true }
    end

    context "sha256 is empty" do
      let(:sha256) { "" }

      it { is_expected.to be true }
    end

    context "sha256 is a valid shasum" do
      let(:sha256) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }

      it { is_expected.to be true }
    end
  end

  describe "#verify" do
    subject { verification.verify }

    let(:computed) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }

    before do
      allow(verification).to receive(:computed).and_return(computed)
    end

    context "sha256 matches computed" do
      let(:sha256) { computed }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "sha256 is :no_check" do
      let(:sha256) { :no_check }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "sha256 does not match computed" do
      let(:sha256) { "d3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33f" }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MismatchError)
      end
    end

    context "sha256 is nil" do
      let(:sha256) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MissingError)
      end
    end

    context "sha256 is empty" do
      let(:sha256) { "" }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MissingError)
      end
    end
  end
end
