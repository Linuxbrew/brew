require "utils/git"

describe Git do
  before do
    git = HOMEBREW_SHIMS_PATH/"scm/git"

    HOMEBREW_CACHE.cd do
      system git, "init"

      File.open(file, "w") { |f| f.write("blah") }
      system git, "add", HOMEBREW_CACHE/file
      system git, "commit", "-m", "'File added'"
      @h1 = `git rev-parse HEAD`

      File.open(file, "w") { |f| f.write("brew") }
      system git, "add", HOMEBREW_CACHE/file
      system git, "commit", "-m", "'written to File'"
      @h2 = `git rev-parse HEAD`
    end
  end

  let(:file) { "blah.rb" }
  let(:hash1) { @h1[0..6] }
  let(:hash2) { @h2[0..6] }

  describe "#last_revision_commit_of_file" do
    it "gives last revision commit when before_commit is nil" do
      expect(
        described_class.last_revision_commit_of_file(HOMEBREW_CACHE, file),
      ).to eq(hash1)
    end

    it "gives revision commit based on before_commit when it is not nil" do
      expect(
        described_class.last_revision_commit_of_file(HOMEBREW_CACHE,
                                                    file,
                                                    before_commit: hash2),
      ).to eq(hash2)
    end
  end

  describe "#last_revision_of_file" do
    it "returns last revision of file" do
      expect(
        described_class.last_revision_of_file(HOMEBREW_CACHE,
                                              HOMEBREW_CACHE/file),
      ).to eq("blah")
    end

    it "returns last revision of file based on before_commit" do
      expect(
        described_class.last_revision_of_file(HOMEBREW_CACHE, HOMEBREW_CACHE/file,
                                              before_commit: "0..3"),
      ).to eq("brew")
    end
  end
end

describe Utils do
  before do
    described_class.clear_git_available_cache
  end

  describe "::git_available?" do
    it "returns true if git --version command succeeds" do
      expect(described_class).to be_git_available
    end

    it "returns false if git --version command does not succeed" do
      stub_const("HOMEBREW_SHIMS_PATH", HOMEBREW_PREFIX/"bin/shim")
      expect(described_class).not_to be_git_available
    end
  end

  describe "::git_path" do
    it "returns nil when git is not available" do
      stub_const("HOMEBREW_SHIMS_PATH", HOMEBREW_PREFIX/"bin/shim")
      expect(described_class.git_path).to eq(nil)
    end

    it "returns path of git when git is available" do
      expect(described_class.git_path).to end_with("git")
    end
  end

  describe "::git_version" do
    it "returns nil when git is not available" do
      stub_const("HOMEBREW_SHIMS_PATH", HOMEBREW_PREFIX/"bin/shim")
      expect(described_class.git_path).to eq(nil)
    end

    it "returns version of git when git is available" do
      expect(described_class.git_version).not_to be_nil
    end
  end

  describe "::ensure_git_installed!" do
    it "returns nil if git already available" do
      expect(described_class.ensure_git_installed!).to be_nil
    end

    context "when git is not already available" do
      before do
        stub_const("HOMEBREW_SHIMS_PATH", HOMEBREW_PREFIX/"bin/shim")
      end

      it "can't install brewed git if homebrew/core is unavailable" do
        allow_any_instance_of(Pathname).to receive(:directory?).and_return(false)
        expect { described_class.ensure_git_installed! }.to raise_error("Git is unavailable")
      end

      it "raises error if can't install git" do
        stub_const("HOMEBREW_BREW_FILE", HOMEBREW_PREFIX/"bin/brew")
        expect { described_class.ensure_git_installed! }.to raise_error("Git is unavailable")
      end

      it "installs git" do
        allow(Homebrew).to receive(:_system).with(any_args).and_return(true)
        described_class.ensure_git_installed!
      end
    end
  end

  describe "::git_remote_exists?" do
    it "returns true when git is not available" do
      stub_const("HOMEBREW_SHIMS_PATH", HOMEBREW_PREFIX/"bin/shim")
      expect(described_class).to be_git_remote_exists("blah")
    end

    context "when git is available" do
      it "returns true when git remote exists", :needs_network do
        git = HOMEBREW_SHIMS_PATH/"scm/git"
        url = "https://github.com/Homebrew/homebrew.github.io"
        repo = HOMEBREW_CACHE/"hey"
        repo.mkpath

        repo.cd do
          system git, "init"
          system git, "remote", "add", "origin", url
        end

        expect(described_class).to be_git_remote_exists(url)
      end

      it "returns false when git remote does not exist" do
        expect(described_class).not_to be_git_remote_exists("blah")
      end
    end
  end
end
