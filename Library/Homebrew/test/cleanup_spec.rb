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

  specify "::update_disk_cleanup_size" do
    shutup do
      described_class.instance_eval("@disk_cleanup_size = 0")
      described_class.update_disk_cleanup_size(128)
    end
    expect(described_class.instance_variable_get("@disk_cleanup_size")).to eq(128)
  end

  specify "::disk_cleanup_size" do
    shutup do
      described_class.instance_eval("@disk_cleanup_size = 0")
    end
    expect(described_class.disk_cleanup_size).to eq(described_class.instance_variable_get("@disk_cleanup_size"))
  end

  specify "::unremovable_kegs" do
    shutup do
      described_class.unremovable_kegs
    end
    expect(described_class.instance_variable_get("@unremovable_kegs")).to eq([])
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
  end
end
