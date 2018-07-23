require_relative "shared_examples"

describe UnpackStrategy::Tar do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.tar.gz" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["container"]

  context "when TAR archive is corrupted" do
    let(:path) {
      (mktmpdir/"test.tar").tap do |path|
        FileUtils.touch path
      end
    }

    include_examples "UnpackStrategy::detect"
  end
end
