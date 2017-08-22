require "download_strategy"

describe AbstractDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "foo" }
  let(:url) { "http://example.com/foo.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }
  let(:args) { %w[foo bar baz] }

  describe "#expand_safe_system_args" do
    it "works with an explicit quiet flag" do
      args << { quiet_flag: "--flag" }
      expanded_args = subject.expand_safe_system_args(args)
      expect(expanded_args).to eq(%w[foo bar baz --flag])
    end

    it "adds an implicit quiet flag" do
      expanded_args = subject.expand_safe_system_args(args)
      expect(expanded_args).to eq(%w[foo bar -q baz])
    end

    it "does not mutate the arguments" do
      result = subject.expand_safe_system_args(args)
      expect(args).to eq(%w[foo bar baz])
      expect(result).not_to be args
    end
  end

  specify "#source_modified_time" do
    FileUtils.mktemp "mtime" do
      FileUtils.touch "foo", mtime: Time.now - 10
      FileUtils.touch "bar", mtime: Time.now - 100
      FileUtils.ln_s "not-exist", "baz"
      expect(subject.source_modified_time).to eq(File.mtime("foo"))
    end
  end
end

describe VCSDownloadStrategy do
  let(:url) { "http://example.com/bar" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  describe "#cached_location" do
    it "returns the path of the cached resource" do
      allow_any_instance_of(described_class).to receive(:cache_tag).and_return("foo")
      downloader = described_class.new("baz", resource)
      expect(downloader.cached_location).to eq(HOMEBREW_CACHE/"baz--foo")
    end
  end
end

describe GitHubPrivateRepositoryDownloadStrategy do
  subject { described_class.new("foo", resource) }
  let(:url) { "https://github.com/owner/repo/archive/1.1.5.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  before(:each) do
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    allow(GitHub).to receive(:repository).and_return({})
  end

  it "sets the @github_token instance variable" do
    expect(subject.instance_variable_get(:@github_token)).to eq("token")
  end

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@owner)).to eq("owner")
    expect(subject.instance_variable_get(:@repo)).to eq("repo")
    expect(subject.instance_variable_get(:@filepath)).to eq("archive/1.1.5.tar.gz")
  end

  its(:download_url) { is_expected.to eq("https://token@github.com/owner/repo/archive/1.1.5.tar.gz") }
end

describe GitHubPrivateRepositoryReleaseDownloadStrategy do
  subject { described_class.new("foo", resource) }
  let(:url) { "https://github.com/owner/repo/releases/download/tag/foo_v0.1.0_darwin_amd64.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  before(:each) do
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    allow(GitHub).to receive(:repository).and_return({})
  end

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@owner)).to eq("owner")
    expect(subject.instance_variable_get(:@repo)).to eq("repo")
    expect(subject.instance_variable_get(:@tag)).to eq("tag")
    expect(subject.instance_variable_get(:@filename)).to eq("foo_v0.1.0_darwin_amd64.tar.gz")
  end

  describe "#download_url" do
    it "returns the download URL for a given resource" do
      allow(subject).to receive(:resolve_asset_id).and_return(456)
      expect(subject.download_url).to eq("https://token@api.github.com/repos/owner/repo/releases/assets/456")
    end
  end

  specify "#resolve_asset_id" do
    release_metadata = {
      "assets" => [
        {
          "id" => 123,
          "name" => "foo_v0.1.0_linux_amd64.tar.gz",
        },
        {
          "id" => 456,
          "name" => "foo_v0.1.0_darwin_amd64.tar.gz",
        },
      ],
    }
    allow(subject).to receive(:fetch_release_metadata).and_return(release_metadata)
    expect(subject.send(:resolve_asset_id)).to eq(456)
  end

  describe "#fetch_release_metadata" do
    it "fetches release metadata from GitHub" do
      expected_release_url = "https://api.github.com/repos/owner/repo/releases/tags/tag"
      expect(GitHub).to receive(:open).with(expected_release_url).and_return({})
      subject.send(:fetch_release_metadata)
    end
  end
end

describe GitHubGitDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "brew" }
  let(:url) { "https://github.com/homebrew/brew.git" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@user)).to eq("homebrew")
    expect(subject.instance_variable_get(:@repo)).to eq("brew")
  end
end

describe GitDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "baz" }
  let(:url) { "https://github.com/homebrew/foo" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }
  let(:cached_location) { subject.cached_location }

  before(:each) do
    @commit_id = 1
    FileUtils.mkpath cached_location
  end

  def git_commit_all
    system "git", "add", "--all"
    system "git", "commit", "-m", "commit number #{@commit_id}"
    @commit_id += 1
  end

  def setup_git_repo
    system "git", "init"
    system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
    FileUtils.touch "README"
    git_commit_all
  end

  describe "#source_modified_time" do
    it "returns the right modification time" do
      cached_location.cd do
        setup_git_repo
      end
      expect(subject.source_modified_time.to_i).to eq(1_485_115_153)
    end
  end

  specify "#last_commit" do
    cached_location.cd do
      setup_git_repo
      FileUtils.touch "LICENSE"
      git_commit_all
    end
    expect(subject.last_commit).to eq("f68266e")
  end

  describe "#fetch_last_commit" do
    let(:url) { "file://#{remote_repo}" }
    let(:version) { Version.create("HEAD") }
    let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: version) }
    let(:remote_repo) { HOMEBREW_PREFIX/"remote_repo" }

    before(:each) { remote_repo.mkpath }

    after(:each) { FileUtils.rm_rf remote_repo }

    it "fetches the hash of the last commit" do
      remote_repo.cd do
        setup_git_repo
        FileUtils.touch "LICENSE"
        git_commit_all
      end

      subject.shutup!
      expect(subject.fetch_last_commit).to eq("f68266e")
    end
  end
end

describe CurlDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "foo" }
  let(:url) { "http://example.com/foo.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: { user: "download:123456" }, version: nil) }

  it "parses the opts and sets the corresponding args" do
    expect(subject.send(:_curl_opts)).to eq(["--user", "download:123456"])
  end
end

describe DownloadStrategyDetector do
  describe "::detect" do
    subject { described_class.detect(url) }
    let(:url) { Object.new }

    context "when given Git URL" do
      let(:url) { "git://example.com/foo.git" }
      it { is_expected.to eq(GitDownloadStrategy) }
    end

    context "when given a GitHub Git URL" do
      let(:url) { "https://github.com/homebrew/brew.git" }
      it { is_expected.to eq(GitHubGitDownloadStrategy) }
    end

    it "defaults to cURL" do
      expect(subject).to eq(CurlDownloadStrategy)
    end

    it "raises an error when passed an unrecognized strategy" do
      expect {
        described_class.detect("foo", Class.new)
      }.to raise_error(TypeError)
    end
  end
end
