require_relative "shared_examples"

describe UnpackStrategy::Cvs do
  let(:repo) {
    mktmpdir.tap do |repo|
      FileUtils.touch repo/"test"
      (repo/"CVS").mkpath
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["CVS", "test"]
end
