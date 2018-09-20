require "test/support/fixtures/testball"
require "cleanup"
require "cask/cache"
require "fileutils"

using CleanupRefinement

describe CleanupRefinement do
  describe "::prune?" do
    alias_matcher :be_pruned, :be_prune

    subject(:path) { HOMEBREW_CACHE/"foo" }

    before do
      path.mkpath
    end

    it "returns true when path_modified_time < days_default" do
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 2 * 60 * 60 * 24)
      expect(path.prune?(1)).to be true
    end

    it "returns false when path_modified_time >= days_default" do
      expect(path.prune?(2)).to be false
    end
  end
end

describe Homebrew::Cleanup do
  let(:ds_store) { Pathname.new("#{HOMEBREW_CELLAR}/.DS_Store") }
  let(:lock_file) { Pathname.new("#{HOMEBREW_LOCKS}/foo") }

  around do |example|
    begin
      FileUtils.touch ds_store
      FileUtils.touch lock_file

      example.run
    ensure
      FileUtils.rm_f ds_store
      FileUtils.rm_f lock_file
    end
  end

  describe "::cleanup" do
    it "removes .DS_Store and lock files" do
      subject.clean!

      expect(ds_store).not_to exist
      expect(lock_file).not_to exist
    end

    it "doesn't remove anything if `dry_run` is true" do
      described_class.new(dry_run: true).clean!

      expect(ds_store).to exist
      expect(lock_file).to exist
    end

    it "doesn't remove the lock file if it is locked" do
      lock_file.open(File::RDWR | File::CREAT).flock(File::LOCK_EX | File::LOCK_NB)

      subject.clean!

      expect(lock_file).to exist
    end

    context "when it can't remove a keg" do
      let(:f1) { Class.new(Testball) { version "0.1" }.new }
      let(:f2) { Class.new(Testball) { version "0.2" }.new }

      before do
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
        subject.cleanup_formula f2
        expect(f1.installed_kegs.size).to eq(2)
      end

      it "lists the unremovable kegs" do
        subject.cleanup_formula f2
        expect(subject.unremovable_kegs).to contain_exactly(f1.installed_kegs[0])
      end
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

    subject.cleanup_formula f3

    expect(f1).not_to be_installed
    expect(f2).not_to be_installed
    expect(f3).to be_installed
    expect(f4).to be_installed
  end

  describe "#cleanup_cask", :cask do
    before do
      Cask::Cache.path.mkpath
    end

    context "when given a versioned cask" do
      let(:cask) { Cask::CaskLoader.load("local-transmission") }

      it "removes the download if it is not for the latest version" do
        download = Cask::Cache.path/"#{cask.token}--7.8.9"

        FileUtils.touch download

        subject.cleanup_cask(cask)

        expect(download).not_to exist
      end

      it "does not remove downloads for the latest version" do
        download = Cask::Cache.path/"#{cask.token}--#{cask.version}"

        FileUtils.touch download

        subject.cleanup_cask(cask)

        expect(download).to exist
      end
    end

    context "when given a `:latest` cask" do
      let(:cask) { Cask::CaskLoader.load("latest-with-appcast") }

      it "does not remove the download for the latest version" do
        download = Cask::Cache.path/"#{cask.token}--#{cask.version}"

        FileUtils.touch download

        subject.cleanup_cask(cask)

        expect(download).to exist
      end

      it "removes the download for the latest version after a week" do
        download = Cask::Cache.path/"#{cask.token}--#{cask.version}"

        FileUtils.touch download, mtime: Time.now - 7 * 60 * 60 * 24

        subject.cleanup_cask(cask)

        expect(download).not_to exist
      end
    end
  end

  describe "::cleanup_logs" do
    let(:path) { (HOMEBREW_LOGS/"delete_me") }

    before do
      path.mkpath
    end

    it "cleans all logs if prune is 0" do
      described_class.new(days: 0).cleanup_logs
      expect(path).not_to exist
    end

    it "cleans up logs if older than 14 days" do
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 15 * 60 * 60 * 24)
      subject.cleanup_logs
      expect(path).not_to exist
    end

    it "does not clean up logs less than 14 days old" do
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 2 * 60 * 60 * 24)
      subject.cleanup_logs
      expect(path).to exist
    end
  end

  describe "::cleanup_cache" do
    it "cleans up incomplete downloads" do
      incomplete = (HOMEBREW_CACHE/"something.incomplete")
      incomplete.mkpath

      subject.cleanup_cache

      expect(incomplete).not_to exist
    end

    it "cleans up 'cargo_cache'" do
      cargo_cache = (HOMEBREW_CACHE/"cargo_cache")
      cargo_cache.mkpath

      subject.cleanup_cache

      expect(cargo_cache).not_to exist
    end

    it "cleans up 'go_cache'" do
      go_cache = (HOMEBREW_CACHE/"go_cache")
      go_cache.mkpath

      subject.cleanup_cache

      expect(go_cache).not_to exist
    end

    it "cleans up 'glide_home'" do
      glide_home = (HOMEBREW_CACHE/"glide_home")
      glide_home.mkpath

      subject.cleanup_cache

      expect(glide_home).not_to exist
    end

    it "cleans up 'java_cache'" do
      java_cache = (HOMEBREW_CACHE/"java_cache")
      java_cache.mkpath

      subject.cleanup_cache

      expect(java_cache).not_to exist
    end

    it "cleans up 'npm_cache'" do
      npm_cache = (HOMEBREW_CACHE/"npm_cache")
      npm_cache.mkpath

      subject.cleanup_cache

      expect(npm_cache).not_to exist
    end

    it "cleans up 'gclient_cache'" do
      gclient_cache = (HOMEBREW_CACHE/"gclient_cache")
      gclient_cache.mkpath

      subject.cleanup_cache

      expect(gclient_cache).not_to exist
    end

    it "cleans up all files and directories" do
      git = (HOMEBREW_CACHE/"gist--git")
      gist = (HOMEBREW_CACHE/"gist")
      svn = (HOMEBREW_CACHE/"gist--svn")

      git.mkpath
      gist.mkpath
      FileUtils.touch svn

      described_class.new(days: 0).cleanup_cache

      expect(git).not_to exist
      expect(gist).to exist
      expect(svn).not_to exist
    end

    it "does not clean up directories that are not VCS checkouts" do
      git = (HOMEBREW_CACHE/"git")
      git.mkpath

      described_class.new(days: 0).cleanup_cache

      expect(git).to exist
    end

    it "cleans up VCS checkout directories with modified time < prune time" do
      foo = (HOMEBREW_CACHE/"--foo")
      foo.mkpath
      allow_any_instance_of(Pathname).to receive(:mtime).and_return(Time.now - 2 * 60 * 60 * 24)
      described_class.new(days: 1).cleanup_cache
      expect(foo).not_to exist
    end

    it "does not clean up VCS checkout directories with modified time >= prune time" do
      foo = (HOMEBREW_CACHE/"--foo")
      foo.mkpath
      described_class.new(days: 1).cleanup_cache
      expect(foo).to exist
    end

    context "cleans old files in HOMEBREW_CACHE" do
      let(:bottle) { (HOMEBREW_CACHE/"testball--0.0.1.tag.bottle.tar.gz") }
      let(:testball) { (HOMEBREW_CACHE/"testball--0.0.1") }
      let(:testball_resource) { (HOMEBREW_CACHE/"testball--rsrc--0.0.1.txt") }

      before do
        FileUtils.touch bottle
        FileUtils.touch testball
        FileUtils.touch testball_resource
        (HOMEBREW_CELLAR/"testball"/"0.0.1").mkpath
        FileUtils.touch(CoreTap.instance.formula_dir/"testball.rb")
      end

      it "cleans up file if outdated" do
        allow(Utils::Bottles).to receive(:file_outdated?).with(any_args).and_return(true)
        subject.cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
        expect(testball_resource).not_to exist
      end

      it "cleans up file if `scrub` is true and formula not installed" do
        described_class.new(scrub: true).cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
        expect(testball_resource).not_to exist
      end

      it "cleans up file if stale" do
        subject.cleanup_cache
        expect(bottle).not_to exist
        expect(testball).not_to exist
        expect(testball_resource).not_to exist
      end
    end
  end
end
