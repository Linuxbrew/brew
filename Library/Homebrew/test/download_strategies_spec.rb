require "download_strategy"

describe AbstractDownloadStrategy do
  subject { described_class.new(url, name, version, **specs) }

  let(:specs) { {} }
  let(:name) { "foo" }
  let(:url) { "https://example.com/foo.tar.gz" }
  let(:version) { nil }
  let(:args) { %w[foo bar baz] }

  specify "#source_modified_time" do
    Mktemp.new("mtime") do
      FileUtils.touch "foo", mtime: Time.now - 10
      FileUtils.touch "bar", mtime: Time.now - 100
      FileUtils.ln_s "not-exist", "baz"
      expect(subject.source_modified_time).to eq(File.mtime("foo"))
    end
  end

  context "when specs[:bottle]" do
    let(:specs) { { bottle: true } }

    it "extends Pourable" do
      expect(subject).to be_a_kind_of(AbstractDownloadStrategy::Pourable)
    end
  end

  context "without specs[:bottle]" do
    it "is does not extend Pourable" do
      expect(subject).not_to be_a_kind_of(AbstractDownloadStrategy::Pourable)
    end
  end
end

describe VCSDownloadStrategy do
  let(:url) { "https://example.com/bar" }
  let(:version) { nil }

  describe "#cached_location" do
    it "returns the path of the cached resource" do
      allow_any_instance_of(described_class).to receive(:cache_tag).and_return("foo")
      downloader = described_class.new(url, "baz", version)
      expect(downloader.cached_location).to eq(HOMEBREW_CACHE/"baz--foo")
    end
  end
end

describe "GitHubPrivateRepositoryDownloadStrategy", :needs_compat do
  subject { GitHubPrivateRepositoryDownloadStrategy.new(url, "foo", version) }

  let(:url) { "https://github.com/owner/repo/archive/1.1.5.tar.gz" }
  let(:version) { nil }

  before do
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

describe "GitHubPrivateRepositoryReleaseDownloadStrategy", :needs_compat do
  subject { GitHubPrivateRepositoryReleaseDownloadStrategy.new(url, "foo", version) }

  let(:url) { "https://github.com/owner/repo/releases/download/tag/foo_v0.1.0_darwin_amd64.tar.gz" }
  let(:version) { nil }

  before do
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
          "id"   => 123,
          "name" => "foo_v0.1.0_linux_amd64.tar.gz",
        },
        {
          "id"   => 456,
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
      expect(GitHub).to receive(:open_api).with(expected_release_url).and_return({})
      subject.send(:fetch_release_metadata)
    end
  end
end

describe GitHubGitDownloadStrategy do
  subject { described_class.new(url, name, version) }

  let(:name) { "brew" }
  let(:url) { "https://github.com/homebrew/brew.git" }
  let(:version) { nil }

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@user)).to eq("homebrew")
    expect(subject.instance_variable_get(:@repo)).to eq("brew")
  end
end

describe GitDownloadStrategy do
  subject { described_class.new(url, name, version) }

  let(:name) { "baz" }
  let(:url) { "https://github.com/homebrew/foo" }
  let(:version) { nil }
  let(:cached_location) { subject.cached_location }

  before do
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
    let(:remote_repo) { HOMEBREW_PREFIX/"remote_repo" }

    before { remote_repo.mkpath }

    after { FileUtils.rm_rf remote_repo }

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

describe "S3DownloadStrategy", :needs_compat do
  subject { S3DownloadStrategy.new(url, name, version) }

  let(:name) { "foo" }
  let(:url) { "https://bucket.s3.amazonaws.com/foo.tar.gz" }
  let(:version) { nil }

  describe "#fetch" do
    context "when given Bad S3 URL" do
      let(:url) { "https://example.com/foo.tar.gz" }

      it "raises Bad S3 URL error" do
        expect { subject.fetch }.to raise_error(RuntimeError, /S3/)
      end
    end
  end
end

describe CurlDownloadStrategy do
  subject { described_class.new(url, name, version, **specs) }

  let(:name) { "foo" }
  let(:url) { "https://example.com/foo.tar.gz" }
  let(:version) { "1.2.3" }
  let(:specs) { { user: "download:123456" } }

  it "parses the opts and sets the corresponding args" do
    expect(subject.send(:_curl_args)).to eq(["--user", "download:123456"])
  end

  describe "#cached_location" do
    subject { described_class.new(url, name, version, **specs).cached_location }

    context "when URL ends with file" do
      it {
        expect(subject).to eq(
          HOMEBREW_CACHE/"downloads/3d1c0ae7da22be9d83fb1eb774df96b7c4da71d3cf07e1cb28555cf9a5e5af70--foo.tar.gz",
        )
      }
    end

    context "when URL file is in middle" do
      let(:url) { "https://example.com/foo.tar.gz/from/this/mirror" }

      it {
        expect(subject).to eq(
          HOMEBREW_CACHE/"downloads/1ab61269ba52c83994510b1e28dd04167a2f2e8393a35a9c50c1f7d33fd8f619--foo.tar.gz",
        )
      }
    end
  end

  describe "#fetch" do
    before do
      subject.temporary_path.dirname.mkpath
      FileUtils.touch subject.temporary_path
    end

    it "calls curl with default arguments" do
      expect(subject).to receive(:curl).with(
        "--location",
        "--remote-time",
        "--continue-at", "0",
        "--output", an_instance_of(Pathname),
        url,
        an_instance_of(Hash)
      )

      subject.fetch
    end

    context "with an explicit user agent" do
      let(:specs) { { user_agent: "Mozilla/25.0.1" } }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["--user-agent", "Mozilla/25.0.1"])
        }

        subject.fetch
      end
    end

    context "with a generalized fake user agent" do
      alias_matcher :a_string_matching, :match

      let(:specs) { { user_agent: :fake } }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2).to_a).to include(
            [
              "--user-agent",
              a_string_matching(/Mozilla.*Mac OS X 10.*AppleWebKit/),
            ],
          )
        }

        subject.fetch
      end
    end

    context "with cookies set" do
      let(:specs) {
        {
          cookies: {
            coo: "kie",
            mon: "ster",
          },
        }
      }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["-b", "coo=kie;mon=ster"])
        }

        subject.fetch
      end
    end

    context "with referer set" do
      let(:specs) { { referer: "https://somehost/also" } }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["-e", "https://somehost/also"])
        }

        subject.fetch
      end
    end
  end

  describe "#cached_location" do
    context "with a file name trailing the URL path" do
      let(:url) { "https://example.com/cask.dmg" }

      its("cached_location.extname") { is_expected.to eq(".dmg") }
    end

    context "with a file name trailing the first query parameter" do
      let(:url) { "https://example.com/download?file=cask.zip&a=1" }

      its("cached_location.extname") { is_expected.to eq(".zip") }
    end

    context "with a file name trailing the second query parameter" do
      let(:url) { "https://example.com/dl?a=1&file=cask.zip&b=2" }

      its("cached_location.extname") { is_expected.to eq(".zip") }
    end

    context "with an unusually long query string" do
      let(:url) do
        [
          "https://node49152.ssl.fancycdn.example.com",
          "/fancycdn/node/49152/file/upload/download",
          "?cask_class=zf920df",
          "&cask_group=2348779087242312",
          "&cask_archive_file_name=cask.zip",
          "&signature=CGmDulxL8pmutKTlCleNTUY%2FyO9Xyl5u9yVZUE0",
          "uWrjadjuz67Jp7zx3H7NEOhSyOhu8nzicEHRBjr3uSoOJzwkLC8L",
          "BLKnz%2B2X%2Biq5m6IdwSVFcLp2Q1Hr2kR7ETn3rF1DIq5o0lHC",
          "yzMmyNe5giEKJNW8WF0KXriULhzLTWLSA3ZTLCIofAdRiiGje1kN",
          "YY3C0SBqymQB8CG3ONn5kj7CIGbxrDOq5xI2ZSJdIyPysSX7SLvE",
          "DBw2KdR24q9t1wfjS9LUzelf5TWk6ojj8p9%2FHjl%2Fi%2FVCXN",
          "N4o1mW%2FMayy2tTY1qcC%2FTmqI1ulZS8SNuaSgr9Iys9oDF1%2",
          "BPK%2B4Sg==",
        ].join
      end

      its("cached_location.extname") { is_expected.to eq(".zip") }
      its("cached_location.to_path.length") { is_expected.to be_between(0, 255) }
    end
  end
end

describe CurlPostDownloadStrategy do
  subject { described_class.new(url, name, version, **specs) }

  let(:name) { "foo" }
  let(:url) { "https://example.com/foo.tar.gz" }
  let(:version) { "1.2.3" }
  let(:specs) { {} }

  describe "#fetch" do
    before do
      subject.temporary_path.dirname.mkpath
      FileUtils.touch subject.temporary_path
    end

    context "with :using and :data specified" do
      let(:specs) {
        {
          using: :post,
          data:  {
            form: "data",
            is:   "good",
          },
        }
      }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["-d", "form=data"])
          expect(args.each_cons(2)).to include(["-d", "is=good"])
        }

        subject.fetch
      end
    end

    context "with :using but no :data" do
      let(:specs) { { using: :post } }

      it "adds the appropriate curl args" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["-X", "POST"])
        }

        subject.fetch
      end
    end
  end
end

describe "ScpDownloadStrategy", :needs_compat do
  subject { ScpDownloadStrategy.new(url, name, version) }

  let(:name) { "foo" }
  let(:url) { "scp://example.com/foo.tar.gz" }
  let(:version) { nil }

  describe "#initialize" do
    invalid_urls = %w[
      https://example.com/foo.tar.gz
      scp://@example.com/foo.tar.gz
      scp://example.com:/foo.tar.gz
      scp://example.com
    ]

    invalid_urls.each do |invalid_url|
      context "with invalid URL #{invalid_url}" do
        let(:url) { invalid_url }

        it "raises ScpDownloadStrategyError" do
          expect { subject }.to raise_error(ScpDownloadStrategyError)
        end
      end
    end
  end

  describe "#fetch" do
    before do
      expect(subject.temporary_path).to receive(:rename).and_return(true)
    end

    context "when given a valid URL" do
      let(:url) { "scp://example.com/foo.tar.gz" }

      it "copies the file via scp" do
        expect(subject)
          .to receive(:system_command!)
          .with("scp", args: ["example.com:/foo.tar.gz", anything])
          .and_return(true)

        subject.fetch
      end
    end

    context "when given a URL with a username" do
      let(:url) { "scp://user@example.com/foo.tar.gz" }

      it "copies the file via scp" do
        expect(subject)
          .to receive(:system_command!)
          .with("scp", args: ["user@example.com:/foo.tar.gz", anything])
          .and_return(true)

        subject.fetch
      end
    end

    context "when given a URL with a port" do
      let(:url) { "scp://example.com:1234/foo.tar.gz" }

      it "copies the file via scp" do
        expect(subject)
          .to receive(:system_command!)
          .with("scp", args: ["-P 1234 example.com:/foo.tar.gz", anything])
          .and_return(true)

        subject.fetch
      end
    end

    context "when given a URL with /~/" do
      let(:url) { "scp://example.com/~/foo.tar.gz" }

      it "treats the path as relative to the home directory" do
        expect(subject)
          .to receive(:system_command!)
          .with("scp", args: ["example.com:~/foo.tar.gz", anything])
          .and_return(true)

        subject.fetch
      end
    end
  end
end

describe SubversionDownloadStrategy do
  subject { described_class.new(url, name, version, **specs) }

  let(:name) { "foo" }
  let(:url) { "https://example.com/foo.tar.gz" }
  let(:version) { "1.2.3" }
  let(:specs) { {} }

  describe "#fetch" do
    context "with :trust_cert set" do
      let(:specs) { { trust_cert: true } }

      it "adds the appropriate svn args" do
        expect(subject).to receive(:system_command!)
          .with("svn", args: array_including("--trust-server-cert",
                                             "--non-interactive"))
        subject.fetch
      end
    end

    context "with :revision set" do
      let(:specs) { { revision: "10" } }

      it "adds svn arguments for :revision" do
        expect(subject).to receive(:system_command!) { |*, args:, **|
          expect(args.each_cons(2)).to include(["-r", "10"])
        }

        subject.fetch
      end
    end
  end
end

describe DownloadStrategyDetector do
  describe "::detect" do
    subject { described_class.detect(url, strategy) }

    let(:url) { Object.new }
    let(:strategy) { nil }

    context "when given Git URL" do
      let(:url) { "git://example.com/foo.git" }

      it { is_expected.to eq(GitDownloadStrategy) }
    end

    context "when given a GitHub Git URL" do
      let(:url) { "https://github.com/homebrew/brew.git" }

      it { is_expected.to eq(GitHubGitDownloadStrategy) }
    end

    context "when given an S3 URL", :needs_compat do
      let(:url) { "s3://bucket/homebrew/brew.tar.gz" }

      it "returns S3DownloadStrategy" do
        allow(described_class).to receive(:require_aws_sdk).and_return(true)
        expect(subject).to eq(S3DownloadStrategy)
      end
    end

    context "when given strategy = S3DownloadStrategy", :needs_compat do
      let(:url) { "https://bkt.s3.amazonaws.com/key.tar.gz" }
      let(:strategy) { S3DownloadStrategy }

      it "requires aws-sdk-s3" do
        allow(described_class).to receive(:require_aws_sdk).and_return(true)
        expect(subject).to eq(S3DownloadStrategy)
      end
    end

    context "when given an scp URL", :needs_compat do
      let(:url) { "scp://example.com/brew.tar.gz" }

      it { is_expected.to eq(ScpDownloadStrategy) }
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
