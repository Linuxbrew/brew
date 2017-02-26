require "testing_env"
require "test/support/fixtures/testball"
require "cleanup"
require "fileutils"
require "pathname"
require "testing_env"

class CleanupTests < Homebrew::TestCase
  def setup
    super
    @ds_store = Pathname.new "#{HOMEBREW_PREFIX}/Library/.DS_Store"
    FileUtils.touch @ds_store
  end

  def teardown
    FileUtils.rm_f @ds_store
    super
  end

  def test_cleanup
    shutup { Homebrew::Cleanup.cleanup }
    refute_predicate @ds_store, :exist?
  end

  def test_cleanup_dry_run
    ARGV << "--dry-run"
    shutup { Homebrew::Cleanup.cleanup }
    assert_predicate @ds_store, :exist?
  end

  def test_cleanup_formula
    f1 = Class.new(Testball) do
      version "1.0"
    end.new
    f2 = Class.new(Testball) do
      version "0.2"
      version_scheme 1
    end.new
    f3 = Class.new(Testball) do
      version "0.3"
      version_scheme 1
    end.new
    f4 = Class.new(Testball) do
      version "0.1"
      version_scheme 2
    end.new

    shutup do
      [f1, f2, f3, f4].each do |f|
        f.brew { f.install }
        Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
      end
    end

    assert_predicate f1, :installed?
    assert_predicate f2, :installed?
    assert_predicate f3, :installed?
    assert_predicate f4, :installed?

    shutup { Homebrew::Cleanup.cleanup_formula f3 }

    refute_predicate f1, :installed?
    refute_predicate f2, :installed?
    assert_predicate f3, :installed?
    assert_predicate f4, :installed?
  end

  def test_cleanup_logs
    path = (HOMEBREW_LOGS/"delete_me")
    path.mkpath
    ARGV << "--prune=all"
    shutup { Homebrew::Cleanup.cleanup_logs }
    refute_predicate path, :exist?
  end

  def test_cleanup_cache_incomplete_downloads
    incomplete = (HOMEBREW_CACHE/"something.incomplete")
    incomplete.mkpath
    shutup { Homebrew::Cleanup.cleanup_cache }
    refute_predicate incomplete, :exist?
  end

  def test_cleanup_cache_java_cache
    java_cache = (HOMEBREW_CACHE/"java_cache")
    java_cache.mkpath
    shutup { Homebrew::Cleanup.cleanup_cache }
    refute_predicate java_cache, :exist?
  end

  def test_cleanup_cache_npm_cache
    npm_cache = (HOMEBREW_CACHE/"npm_cache")
    npm_cache.mkpath
    shutup { Homebrew::Cleanup.cleanup_cache }
    refute_predicate npm_cache, :exist?
  end
end
