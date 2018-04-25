require "requirements/non_binary_osxfuse_requirement"

describe NonBinaryOsxfuseRequirement, :needs_macos do
  subject { described_class.new([]) }

  describe "#message" do
    its(:message) { is_expected.to match("osxfuse is already installed from the binary distribution") }
  end
end
