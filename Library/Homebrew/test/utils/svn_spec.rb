require "utils/svn"

describe Utils do
  describe "#self.svn_available?" do
    it "returns true if svn --version command succeeds" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
      expect(described_class.svn_available?).to be_truthy
    end

    it "returns false if svn --version command does not succeed" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
      expect(described_class.svn_available?).to be_falsey
    end

    it "returns svn version if already set" do
      described_class.instance_variable_set(:@svn, true)
      expect(described_class.svn_available?).to be_truthy
    end
  end

  describe "#self.svn_remote_exists" do
    let(:url) { "https://dl.bintray.com/homebrew/mirror/" }

    it "returns true when svn is not available" do
      described_class.instance_variable_set(:@svn, false)
      expect(described_class.svn_remote_exists(url)).to be_truthy
    end

    it "returns false when remote does not exist" do
      expect(described_class.svn_remote_exists(url)).to be_falsey
    end

    it "returns true when remote exists" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
      expect(described_class.svn_remote_exists(url)).to be_truthy
    end
  end
end
