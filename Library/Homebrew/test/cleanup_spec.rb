require "test/support/fixtures/testball"
require "cleanup"
require "fileutils"
require "pathname"

describe Homebrew::Cleanup do
  let(:ds_store) { Pathname.new("#{HOMEBREW_PREFIX}/Library/.DS_Store") }

  around(:each) do |example|
    begin
      FileUtils.touch ds_store

      example.run
    ensure
      FileUtils.rm_f ds_store
    end
  end

  describe "::cleanup" do
    it "removes .DS_Store files" do
      shutup do
        described_class.cleanup
      end

      expect(ds_store).not_to exist
    end

    it "doesn't remove anything if `--dry-run` is specified" do
      ARGV << "--dry-run"

      shutup do
        described_class.cleanup
      end

      expect(ds_store).to exist
    end
  end

  specify "::cleanup_formula" do
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
        f.brew do
          f.install
        end

        Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
      end
    end

    expect(f1).to be_installed
    expect(f2).to be_installed
    expect(f3).to be_installed
    expect(f4).to be_installed

    shutup do
      described_class.cleanup_formula f3
    end

    expect(f1).not_to be_installed
    expect(f2).not_to be_installed
    expect(f3).to be_installed
    expect(f4).to be_installed
  end

  specify "::cleanup_logs" do
    path = (HOMEBREW_LOGS/"delete_me")
    path.mkpath
    ARGV << "--prune=all"

    shutup do
      described_class.cleanup_logs
    end

    expect(path).not_to exist
  end

  describe "::cleanup_cache" do
    it "cleans up incomplete downloads" do
      incomplete = (HOMEBREW_CACHE/"something.incomplete")
      incomplete.mkpath

      shutup do
        described_class.cleanup_cache
      end

      expect(incomplete).not_to exist
    end

    it "cleans up 'java_cache'" do
      java_cache = (HOMEBREW_CACHE/"java_cache")
      java_cache.mkpath

      shutup do
        described_class.cleanup_cache
      end

      expect(java_cache).not_to exist
    end

    it "cleans up 'npm_cache'" do
      npm_cache = (HOMEBREW_CACHE/"npm_cache")
      npm_cache.mkpath

      shutup do
        described_class.cleanup_cache
      end

      expect(npm_cache).not_to exist
    end
  end
end
