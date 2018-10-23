require "requirements/codesign_requirement"

describe CodesignRequirement do
  subject(:requirement) {
    described_class.new([{ identity: identity, with: with, url: url }])
  }

  let(:identity) { "lldb_codesign" }
  let(:with) { "LLDB" }
  let(:url) {
    "https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt"
  }

  describe "#message" do
    it "includes all parameters" do
      expect(requirement.message).to include(identity)
      expect(requirement.message).to include(with)
      expect(requirement.message).to include(url)
    end
  end
end
