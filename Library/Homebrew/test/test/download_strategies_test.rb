require "testing_env"
require "download_strategy"

class ResourceDouble
  attr_reader :url, :specs, :version

  def initialize(url = "http://example.com/foo.tar.gz", specs = {})
    @url = url
    @specs = specs
  end
end

class AbstractDownloadStrategyTests < Homebrew::TestCase
  include FileUtils

  def setup
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

class GitDownloadStrategyTests < Homebrew::TestCase
  include FileUtils

  def setup
    resource = ResourceDouble.new("https://github.com/homebrew/foo")
    @commit_id = 1
    @strategy = GitDownloadStrategy.new("baz", resource)
    @cached_location = @strategy.cached_location
    mkpath @cached_location
  end

  def teardown
    rmtree @cached_location
  end

  def git_commit_all
    shutup do
      system "git", "add", "--all"
      system "git", "commit", "-m", "commit number #{@commit_id}"
      @commit_id += 1
    end
  end

  def using_git_env
    initial_env = ENV.to_hash
    %w[AUTHOR COMMITTER].each do |role|
      ENV["GIT_#{role}_NAME"] = "brew tests"
      ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
      ENV["GIT_#{role}_DATE"] = "Thu May 21 00:04:11 2009 +0100"
    end
    yield
  ensure
    ENV.replace(initial_env)
  end

  def setup_git_repo
    using_git_env do
      @cached_location.cd do
        shutup do
          system "git", "init"
          system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
        end
        touch "README"
        git_commit_all
      end
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
    assert_equal 1_242_860_651, @strategy.source_modified_time.to_i
  end

  def test_last_commit
    setup_git_repo
    using_git_env do
      @cached_location.cd do
        touch "LICENSE"
        git_commit_all
      end
    end
    assert_equal "c50c79b", @strategy.last_commit
  end

  def test_fetch_last_commit
    remote_repo = HOMEBREW_PREFIX.join("remote_repo")
    remote_repo.mkdir

    resource = ResourceDouble.new("file://#{remote_repo}")
    resource.instance_variable_set(:@version, Version.create("HEAD"))
    @strategy = GitDownloadStrategy.new("baz", resource)

    using_git_env do
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
    end

    @strategy.shutup!
    assert_equal "c50c79b", @strategy.fetch_last_commit
  ensure
    remote_repo.rmtree if remote_repo.directory?
  end
end

class DownloadStrategyDetectorTests < Homebrew::TestCase
  def setup
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
