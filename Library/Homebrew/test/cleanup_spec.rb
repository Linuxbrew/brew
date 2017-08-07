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
      described_class.cleanup

      expect(ds_store).not_to exist
    end

    it "doesn't remove anything if `--dry-run` is specified" do
      ARGV << "--dry-run"

      described_class.cleanup

      expect(ds_store).to exist
    end

    context "when it can't remove a keg" do
      let(:f1) { Class.new(Testball) { version "0.1" }.new }
      let(:f2) { Class.new(Testball) { version "0.2" }.new }
      let(:unremovable_kegs) { [] }

      before(:each) do
        described_class.instance_variable_set(:@unremovable_kegs, [])
        [f1, f2].each do |f|
          f.brew do
            f.install
          end

          Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
        end

        allow_any_instance_of(Keg)
          .to receive(:uninstall)
          .and_raise(Errno::EACCES)
      end

      it "doesn't remove any kegs" do
        described_class.cleanup_formula f2
        expect(f1.installed_kegs.size).to eq(2)
      end

      it "lists the unremovable kegs" do
        described_class.cleanup_formula f2
        expect(described_class.unremovable_kegs).to contain_exactly(f1.installed_kegs[0])
      end
    end
  end

  specify "::disk_cleanup_size" do
    disk_cleanup_size = described_class.instance_variable_get(:@disk_cleanup_size)
    expect(described_class.disk_cleanup_size).to eq(disk_cleanup_size)
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

    [f1, f2, f3, f4].each do |f|
      f.brew do
        f.install
      end

      Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
    end

    expect(f1).to be_installed
    expect(f2).to be_installed
    expect(f3).to be_installed
    expect(f4).to be_installed

    described_class.cleanup_formula f3

    expect(f1).not_to be_installed
    expect(f2).not_to be_installed
    expect(f3).to be_installed
    expect(f4).to be_installed
  end

  specify "::cleanup_logs" do
    path = (HOMEBREW_LOGS/"delete_me")
    path.mkpath
    ARGV << "--prune=all"

    described_class.cleanup_logs

    expect(path).not_to exist
  end

  describe "::cleanup_cache" do
    it "cleans up incomplete downloads" do
      incomplete = (HOMEBREW_CACHE/"something.incomplete")
      incomplete.mkpath

      described_class.cleanup_cache

      expect(incomplete).not_to exist
    end

    it "cleans up 'java_cache'" do
      java_cache = (HOMEBREW_CACHE/"java_cache")
      java_cache.mkpath

      described_class.cleanup_cache

      expect(java_cache).not_to exist
    end

    it "cleans up 'npm_cache'" do
      npm_cache = (HOMEBREW_CACHE/"npm_cache")
      npm_cache.mkpath

      described_class.cleanup_cache

      expect(npm_cache).not_to exist
    end

    it "cleans up all files and directories" do
      git = (HOMEBREW_CACHE/"gist--git")
      gist = (HOMEBREW_CACHE/"gist")
      svn = (HOMEBREW_CACHE/"gist--svn")
      git.mkpath
      gist.mkpath
      FileUtils.touch svn
      allow(ARGV).to receive(:value).with("prune").and_return("all")
      begin
        described_class.cleanup_cache
        expect(git).not_to exist
        expect(gist).to exist
        expect(svn).not_to exist
      ensure
        FileUtils.rm_rf(git)
        FileUtils.rm_rf(gist)
        FileUtils.rm_rf(svn)
      end
    end

    it "cleans up VCS checkout directories with modified time < prune time" do
      foo = (HOMEBREW_CACHE/"--foo")
      foo.mkpath
      allow(ARGV).to receive(:value).with("prune").and_return("1")
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 60 * 60 * 24 * 2)
      begin
        described_class.cleanup_cache
        expect(foo).not_to exist
      ensure
        FileUtils.rm_rf(foo)
      end
    end

    context "cleans old files in HOMEBREW_CACHE" do
      let(:bottle) { (HOMEBREW_CACHE/"testball-0.0.1.bottle.tar.gz") }
      let(:testball) { (HOMEBREW_CACHE/"testball-0.0.1") }

      before(:each) do
        FileUtils.touch(bottle)
        FileUtils.touch(testball)
        (HOMEBREW_CELLAR/"testball"/"0.0.1").mkpath
        FileUtils.touch(CoreTap.instance.formula_dir/"testball.rb")
      end

      after(:each) do
        FileUtils.rm_rf(bottle)
        FileUtils.rm_rf(testball)
        FileUtils.rm_rf(HOMEBREW_CELLAR/"testball")
        FileUtils.rm_rf(CoreTap.instance.formula_dir/"testball.rb")
      end

      it "cleans up file if outdated" do
        allow(Utils::Bottles).to receive(:file_outdated?).with(any_args).and_return(true)
        described_class.cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
      end

      it "cleans up file if ARGV has -s and formula not installed" do
        ARGV << "-s"
        described_class.cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
      end

      it "cleans up file if stale" do
        puts described_class.cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
      end
    end
  end

  specify "::prune?" do
    foo = mktmpdir/"foo.rb"
    foo.mkpath
    allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 60 * 60 * 24 * 2)
    begin
      expect(described_class.prune?(foo, days_default: "1")).to be_truthy
    ensure
      FileUtils.rm_rf(foo)
    end
  end
end
