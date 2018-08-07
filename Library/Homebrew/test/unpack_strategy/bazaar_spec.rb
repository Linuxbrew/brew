require_relative "shared_examples"

describe UnpackStrategy::Bazaar do
  let(:repo) {
    mktmpdir.tap do |repo|
      FileUtils.touch repo/"test"
      (repo/".bzr").mkpath
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test"]
end
