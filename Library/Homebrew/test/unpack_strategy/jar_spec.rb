require_relative "shared_examples"

describe UnpackStrategy::Jar, :needs_unzip do
  let(:path) { TEST_FIXTURE_DIR/"test.jar" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test.jar"]
end
