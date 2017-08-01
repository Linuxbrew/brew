require "utils/git"

describe Git do
  before(:all) do
    git = HOMEBREW_SHIMS_PATH/"scm/git"
    file = "lib/blah.rb"
    repo = Pathname.new("repo")

    (repo/"lib").mkpath
    system git, "init"
    FileUtils.touch("repo/#{file}")

    File.open(repo/file, "w") { |f| f.write("blah") }
    system git, "add", repo/file
    system git, "commit", "-m", "'File added'"
    @h1 = `git rev-parse HEAD`

    File.open(repo/file, "w") { |f| f.write("brew") }
    system git, "add", repo/file
    system git, "commit", "-m", "'written to File'"
    @h2 = `git rev-parse HEAD`
  end

  let(:file) { "lib/blah.rb" }
  let(:repo) { Pathname.new("repo") }
  let(:hash1) { @h1[0..6] }
  let(:hash2) { @h2[0..6] }

  after(:all) do
    FileUtils.rm_rf("repo")
  end

  describe "#last_revision_commit_of_file" do
    it "gives last revision commit when before_commit is nil" do
      expect(
        described_class.last_revision_commit_of_file(repo, file),
      ).to eq(hash1)
    end

    it "gives revision commit based on before_commit when it is not nil" do
      expect(
        described_class.last_revision_commit_of_file(repo,
                                                    file,
                                                    before_commit: "0..3"),
      ).to eq(hash2)
    end
  end

  describe "#last_revision_of_file" do
    it "returns last revision of file" do
      expect(
        described_class.last_revision_of_file(repo,
                                              repo/file),
      ).to eq("blah")
    end

    it "returns last revision of file based on before_commit" do
      expect(
        described_class.last_revision_of_file(repo, repo/file,
                                              before_commit: "0..3"),
      ).to eq("brew")
    end
  end
end

describe Utils do
  before(:each) do
    if described_class.instance_variable_defined?(:@git)
      described_class.send(:remove_instance_variable, :@git)
    end
  end

  describe "::git_available?" do
    it "returns true if git --version command succeeds" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
      expect(described_class.git_available?).to be_truthy
    end

    it "returns false if git --version command does not succeed" do
      allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
      expect(described_class.git_available?).to be_falsey
    end

    it "returns git version if already set" do
      described_class.instance_variable_set(:@git, true)
      expect(described_class.git_available?).to be_truthy
      described_class.instance_variable_set(:@git, nil)
    end
  end

  describe "::git_path" do
    context "when git is not available" do
      before do
        described_class.instance_variable_set(:@git, false)
      end

      it "returns nil" do
        expect(described_class.git_path).to eq(nil)
      end
    end

    context "when git is available" do
      before do
        described_class.instance_variable_set(:@git, true)
      end

      it "returns path of git" do
        expect(described_class.git_path).to end_with("git")
      end

      it "returns git_path if already set" do
        described_class.instance_variable_set(:@git_path, "git")
        expect(described_class.git_path).to eq("git")
        described_class.instance_variable_set(:@git_path, nil)
      end
    end
  end

  describe "::git_version" do
    context "when git is not available" do
      before do
        described_class.instance_variable_set(:@git, false)
      end

      it "returns nil" do
        expect(described_class.git_path).to eq(nil)
      end
    end

    context "when git is available" do
      before do
        described_class.instance_variable_set(:@git, true)
      end

      it "returns version of git" do
        expect(described_class.git_version).not_to be_nil
      end

      it "returns git_version if already set" do
        described_class.instance_variable_set(:@git_version, "v1")
        expect(described_class.git_version).to eq("v1")
        described_class.instance_variable_set(:@git_version, nil)
      end
    end
  end

  describe "::git_remote_exists" do
    context "when git is not available" do
      before do
        described_class.instance_variable_set(:@git, false)
      end

      it "returns true" do
        expect(described_class.git_remote_exists("blah")).to be_truthy
      end
    end

    context "when git is available" do
      before(:all) do
        described_class.instance_variable_set(:@git, true)
      end

      after(:all) do
        if described_class.instance_variable_defined?(:@git)
          described_class.send(:remove_instance_variable, :@git)
        end
      end

      it "returns true when git remote exists", :needs_network do
        git = HOMEBREW_SHIMS_PATH/"scm/git"
        repo = Pathname.new("hey")
        repo.mkpath

        system "cd", repo
        system git, "init"
        system git, "remote", "add", "origin", "git@github.com:Homebrew/brew"
        system "cd .."

        expect(described_class.git_remote_exists("git@github.com:Homebrew/brew")).to be_truthy

        FileUtils.rm_rf(repo)
      end

      it "returns false when git remote does not exist" do
        expect(described_class.git_remote_exists("blah")).to be_falsey
      end
    end
  end

  describe "::clear_git_available_cache" do
    it "removes @git_path and @git_version if defined" do
      described_class.clear_git_available_cache

      expect(@git_path).to be_nil
      expect(@git_version).to be_nil
    end

    it "removes @git if defined" do
      described_class.instance_variable_set(:@git, true)

      begin
        described_class.clear_git_available_cache

        expect(@git).to be_nil
        expect(@git_path).to be_nil
        expect(@git_version).to be_nil
      ensure
        if described_class.instance_variable_defined?(:@git)
          described_class.send(:remove_instance_variable, :@git)
        end
      end
    end
  end
end
