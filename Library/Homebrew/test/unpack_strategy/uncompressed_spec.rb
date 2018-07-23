require_relative "shared_examples"

describe UnpackStrategy::Uncompressed do
  let(:path) {
    (mktmpdir/"test").tap do |path|
      FileUtils.touch path
    end
  }

  include_examples "UnpackStrategy::detect"
end
