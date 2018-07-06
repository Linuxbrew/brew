describe Hbc::Verify::Checksum, :cask do
  let(:cask) { double("cask", token: "cask") }
  let(:downloaded_path) { instance_double("Pathname") }
  let(:verification) { described_class.new(cask, downloaded_path) }

  before do
    allow(cask).to receive(:sha256).and_return(expected_sha256)
  end

  describe ".me?" do
    subject { described_class.me?(cask) }

    context "when expected sha256 is :no_check" do
      let(:expected_sha256) { :no_check }

      it { is_expected.to be false }
    end

    context "when expected sha256 is nil" do
      let(:expected_sha256) { nil }

      it { is_expected.to be true }
    end

    context "sha256 is empty" do
      let(:expected_sha256) { "" }

      it { is_expected.to be true }
    end

    context "when expected sha256 is a valid shasum" do
      let(:expected_sha256) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }

      it { is_expected.to be true }
    end
  end

  describe "#verify" do
    subject { verification.verify }

    before do
      allow(cask).to receive(:sha256).and_return(expected_sha256)
      allow(downloaded_path).to receive(:sha256).and_return(actual_sha256)
    end

    let(:actual_sha256) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }

    context "when expected matches actual sha256" do
      let(:expected_sha256) { actual_sha256 }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when expected sha256 is :no_check" do
      let(:expected_sha256) { :no_check }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when expected does not match sha256" do
      let(:expected_sha256) { "d3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33fd3adb33f" }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MismatchError)
      end
    end

    context "when expected sha256 is nil" do
      let(:expected_sha256) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MissingError)
      end
    end

    context "when expected sha256 is empty" do
      let(:expected_sha256) { "" }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskSha256MissingError)
      end
    end
  end
end
