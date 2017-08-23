require "utils/svn"

describe Utils do
  describe "#self.svn_available?" do
    before(:each) do
      described_class.clear_svn_version_cache
    end

    it "returns svn version if svn available" do
      expect(described_class.svn_available?).to be_truthy
    end
  end

  describe "#self.svn_remote_exists" do
    it "returns true when svn is not available" do
      allow(Utils).to receive(:svn_available?).and_return(false)
      expect(described_class.svn_remote_exists("blah")).to be_truthy
    end

    context "when svn is available" do
      before do
        allow(Utils).to receive(:svn_available?).and_return(true)
      end

      it "returns false when remote does not exist" do
        expect(described_class.svn_remote_exists(HOMEBREW_CACHE/"install")).to be_falsey
      end

      it "returns true when remote exists", :needs_network do
        remote = "http://github.com/Homebrew/install"
        svn = HOMEBREW_SHIMS_PATH/"scm/svn"

        HOMEBREW_CACHE.cd { system svn, "checkout", remote }

        expect(described_class.svn_remote_exists(HOMEBREW_CACHE/"install")).to be_truthy
      end
    end
  end
end
