require "utils/git"

describe Git do
  before(:all) do
    git = HOMEBREW_SHIMS_PATH/"scm/git"
    file = "lib/blah.rb"
    repo = Pathname.new("repo")
    FileUtils.mkpath("repo/lib")
    `#{git} init`
    FileUtils.touch("repo/#{file}")
    File.open(repo.to_s+"/"+file, "w") { |f| f.write("blah") }
    `#{git} add repo/#{file}`
    `#{git} commit -m"File added"`
    @hash1 = `git rev-parse HEAD`
    File.open(repo.to_s+"/"+file, "w") { |f| f.write("brew") }
    `#{git} add repo/#{file}`
    `#{git} commit -m"written to File"`
    @hash2 = `git rev-parse HEAD`
  end

  let(:file) { "lib/blah.rb" }
  let(:repo) { Pathname.new("repo") }

  # after(:all) do
  #   FileUtils.rm_rf("repo")
  # end

  describe "#last_revision_commit_of_file" do
    it "sets args as --skip=1 when before_commit is nil" do
      expect(described_class.last_revision_commit_of_file(repo, file)).to eq(@hash1[0..6])
    end

    it "sets args as --skip=1 when before_commit is nil" do
      expect(described_class.last_revision_commit_of_file(repo, file, before_commit: "0..3")).to eq(@hash2[0..6])
    end
  end

  describe "#last_revision_of_file" do
    it "returns last revision of file" do
      expect(described_class.last_revision_of_file(repo, repo.to_s+"/"+file)).to eq("blah")
    end

    it "returns last revision of file based on before_commit" do
      expect(described_class.last_revision_of_file(repo, repo.to_s+"/"+file, before_commit: "0..3")).to eq("brew")
    end
  end
end
