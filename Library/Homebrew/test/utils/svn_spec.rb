require "utils/svn"

describe Utils do
  describe "#self.svn_available?" do
    it "processes value when @svn is not defined" do
      expect(described_class.svn_available?).to be_truthy
    end

    it "returns value of @svn when @svn is defined" do
      described_class.instance_variable_set(:@svn, true)
      expect(described_class.svn_available?).to be_truthy
    end
  end

  describe "#self.svn_remote_exists" do
    let(:url) { "https://dl.bintray.com/homebrew/mirror/" }

    it "gives true when @svn is false" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
      described_class.instance_variable_set(:@svn, false)
      expect(described_class.svn_remote_exists(url)).to be_truthy
    end

    it "gives false when url is obscure" do
      expect(described_class.svn_remote_exists(url)).to be_falsy
    end

    it "gives true when quiet_system succeeds with given url" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
      expect(described_class.svn_remote_exists(url)).to be_truthy
    end
  end
end
