require "utils/svn"

describe Utils do
  describe "#self.svn_available?" do
    before do
      described_class.clear_svn_version_cache
    end

    it "returns svn version if svn available" do
      if File.executable? "/usr/bin/svn"
        expect(described_class).to be_svn_available
      else
        expect(described_class).not_to be_svn_available
      end
    end
  end

  describe "#self.svn_remote_exists?" do
    it "returns true when svn is not available" do
      allow(described_class).to receive(:svn_available?).and_return(false)
      expect(described_class).to be_svn_remote_exists("blah")
    end

    context "when svn is available" do
      before do
        allow(described_class).to receive(:svn_available?).and_return(true)
      end

      it "returns false when remote does not exist" do
        expect(described_class).not_to be_svn_remote_exists(HOMEBREW_CACHE/"install")
      end

      it "returns true when remote exists", :needs_network, :needs_svn do
        HOMEBREW_CACHE.cd do
          system HOMEBREW_SHIMS_PATH/"scm/svn", "checkout",
            "--non-interactive", "--trust-server-cert", "--quiet",
            "https://github.com/Homebrew/install"
        end

        expect(described_class).to be_svn_remote_exists(HOMEBREW_CACHE/"install")
      end
    end
  end
end
