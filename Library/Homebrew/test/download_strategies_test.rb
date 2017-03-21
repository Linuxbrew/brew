require "testing_env"
require "download_strategy"

class ResourceDouble
  attr_reader :url, :specs, :version, :mirrors

  def initialize(url = "http://example.com/foo.tar.gz", specs = {})
    @url = url
    @specs = specs
    @mirrors = []
  end
end

class AbstractDownloadStrategyTests < Homebrew::TestCase
  include FileUtils

  def setup
    super
    @name = "foo"
    @resource = ResourceDouble.new
    @strategy = AbstractDownloadStrategy.new(@name, @resource)
    @args = %w[foo bar baz]
  end

  def test_expand_safe_system_args_with_explicit_quiet_flag
    @args << { quiet_flag: "--flag" }
    expanded_args = @strategy.expand_safe_system_args(@args)
    assert_equal %w[foo bar baz --flag], expanded_args
  end

  def test_expand_safe_system_args_with_implicit_quiet_flag
    expanded_args = @strategy.expand_safe_system_args(@args)
    assert_equal %w[foo bar -q baz], expanded_args
  end

  def test_expand_safe_system_args_does_not_mutate_argument
    result = @strategy.expand_safe_system_args(@args)
    assert_equal %w[foo bar baz], @args
    refute_same @args, result
  end

  def test_source_modified_time
    mktemp "mtime" do
      touch "foo", mtime: Time.now - 10
      touch "bar", mtime: Time.now - 100
      ln_s "not-exist", "baz"
      assert_equal File.mtime("foo"), @strategy.source_modified_time
    end
  end
end

class VCSDownloadStrategyTests < Homebrew::TestCase
  def test_cache_filename
    resource = ResourceDouble.new("http://example.com/bar")
    strategy = Class.new(VCSDownloadStrategy) do
      def cache_tag
        "foo"
      end
    end
    downloader = strategy.new("baz", resource)
    assert_equal HOMEBREW_CACHE.join("baz--foo"), downloader.cached_location
  end
end

class GitHubPrivateRepositoryDownloadStrategyTests < Homebrew::TestCase
  def setup
    super
    resource = ResourceDouble.new("https://github.com/owner/repo/archive/1.1.5.tar.gz")
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    GitHub.stubs(:repository).returns {}
    @strategy = GitHubPrivateRepositoryDownloadStrategy.new("foo", resource)
  end

  def test_set_github_token
    assert_equal "token", @strategy.instance_variable_get(:@github_token)
  end

  def test_parse_url_pattern
    assert_equal "owner", @strategy.instance_variable_get(:@owner)
    assert_equal "repo", @strategy.instance_variable_get(:@repo)
    assert_equal "archive/1.1.5.tar.gz", @strategy.instance_variable_get(:@filepath)
  end

  def test_download_url
    expected = "https://token@github.com/owner/repo/archive/1.1.5.tar.gz"
    assert_equal expected, @strategy.download_url
  end
end

class GitHubPrivateRepositoryReleaseDownloadStrategyTests < Homebrew::TestCase
  def setup
    super
    resource = ResourceDouble.new("https://github.com/owner/repo/releases/download/tag/foo_v0.1.0_darwin_amd64.tar.gz")
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    GitHub.stubs(:repository).returns {}
    @strategy = GitHubPrivateRepositoryReleaseDownloadStrategy.new("foo", resource)
  end

  def test_parse_url_pattern
    assert_equal "owner", @strategy.instance_variable_get(:@owner)
    assert_equal "repo", @strategy.instance_variable_get(:@repo)
    assert_equal "tag", @strategy.instance_variable_get(:@tag)
    assert_equal "foo_v0.1.0_darwin_amd64.tar.gz", @strategy.instance_variable_get(:@filename)
  end

  def test_download_url
    @strategy.stubs(:resolve_asset_id).returns(456)
    expected = "https://token@api.github.com/repos/owner/repo/releases/assets/456"
    assert_equal expected, @strategy.download_url
  end

  def test_resolve_asset_id
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
    @strategy.stubs(:fetch_release_metadata).returns(release_metadata)
    assert_equal 456, @strategy.send(:resolve_asset_id)
  end

  def test_fetch_release_metadata
    expected_release_url = "https://api.github.com/repos/owner/repo/releases/tags/tag"
    github_mock = MiniTest::Mock.new
    github_mock.expect :call, {}, [expected_release_url]
    GitHub.stub :open, github_mock do
      @strategy.send(:fetch_release_metadata)
    end
    github_mock.verify
  end
end

class GitDownloadStrategyTests < Homebrew::TestCase
  include FileUtils

  def setup
    super
    resource = ResourceDouble.new("https://github.com/homebrew/foo")
    @commit_id = 1
    @strategy = GitDownloadStrategy.new("baz", resource)
    @cached_location = @strategy.cached_location
    mkpath @cached_location
  end

  def git_commit_all
    shutup do
      system "git", "add", "--all"
      system "git", "commit", "-m", "commit number #{@commit_id}"
      @commit_id += 1
    end
  end

  def setup_git_repo
    @cached_location.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
      end
      touch "README"
      git_commit_all
    end
  end

  def test_github_git_download_strategy_user_repo
    resource = ResourceDouble.new("https://github.com/homebrew/brew.git")
    strategy = GitHubGitDownloadStrategy.new("brew", resource)

    assert_equal strategy.instance_variable_get(:@user), "homebrew"
    assert_equal strategy.instance_variable_get(:@repo), "brew"
  end

  def test_source_modified_time
    setup_git_repo
    assert_equal 1_485_115_153, @strategy.source_modified_time.to_i
  end

  def test_last_commit
    setup_git_repo
    @cached_location.cd do
      touch "LICENSE"
      git_commit_all
    end
    assert_equal "f68266e", @strategy.last_commit
  end

  def test_fetch_last_commit
    remote_repo = HOMEBREW_PREFIX.join("remote_repo")
    remote_repo.mkdir

    resource = ResourceDouble.new("file://#{remote_repo}")
    resource.instance_variable_set(:@version, Version.create("HEAD"))
    @strategy = GitDownloadStrategy.new("baz", resource)

    remote_repo.cd do
      shutup do
        system "git", "init"
        system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
      end
      touch "README"
      git_commit_all
      touch "LICENSE"
      git_commit_all
    end

    @strategy.shutup!
    assert_equal "f68266e", @strategy.fetch_last_commit
  ensure
    remote_repo.rmtree if remote_repo.directory?
  end
end

class DownloadStrategyDetectorTests < Homebrew::TestCase
  def setup
    super
    @d = DownloadStrategyDetector.new
  end

  def test_detect_git_download_startegy
    @d = DownloadStrategyDetector.detect("git://example.com/foo.git")
    assert_equal GitDownloadStrategy, @d
  end

  def test_detect_github_git_download_strategy
    @d = DownloadStrategyDetector.detect("https://github.com/homebrew/brew.git")
    assert_equal GitHubGitDownloadStrategy, @d
  end

  def test_default_to_curl_strategy
    @d = DownloadStrategyDetector.detect(Object.new)
    assert_equal CurlDownloadStrategy, @d
  end

  def test_raises_when_passed_unrecognized_strategy
    assert_raises(TypeError) do
      DownloadStrategyDetector.detect("foo", Class.new)
    end
  end
end
