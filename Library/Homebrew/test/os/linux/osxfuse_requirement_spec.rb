require "requirements/osxfuse_requirement"

describe OsxfuseRequirement do
  subject { described_class.new([]) }

  describe "#message" do
    its(:message) { is_expected.to match("libfuse is required to install this formula") }
  end
end
