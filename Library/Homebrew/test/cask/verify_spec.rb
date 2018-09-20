module Cask
  describe Verify, :cask do
    describe "::all" do
      subject(:verification) { described_class.all(cask, downloaded_path) }

      let(:cask) { instance_double(Cask, token: "cask", sha256: expected_sha256) }
      let(:cafebabe) { "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe" }
      let(:deadbeef) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }
      let(:computed_sha256) { cafebabe }
      let(:downloaded_path) { instance_double(Pathname, sha256: computed_sha256) }

      context "when the expected checksum is :no_check" do
        let(:expected_sha256) { :no_check }

        it "skips the check" do
          expect { verification }.to output(/skipping verification/).to_stdout
        end
      end

      context "when expected and computed checksums match" do
        let(:expected_sha256) { cafebabe }

        it "does not raise an error" do
          expect { verification }.not_to raise_error
        end
      end

      context "when the expected checksum is nil" do
        let(:expected_sha256) { nil }

        it "raises an error" do
          expect { verification }.to raise_error CaskSha256MissingError
        end
      end

      context "when the expected checksum is empty" do
        let(:expected_sha256) { "" }

        it "raises an error" do
          expect { verification }.to raise_error CaskSha256MissingError
        end
      end

      context "when expected and computed checksums do not match" do
        let(:expected_sha256) { deadbeef }

        it "raises an error" do
          expect { verification }.to raise_error CaskSha256MismatchError
        end
      end
    end
  end
end
