require "update_migrator"

describe UpdateMigrator do
  describe "::migrate_cache_entries_to_double_dashes" do
    let(:formula_name) { "foo" }
    let(:f) {
      formula formula_name do
        url "https://brew.sh/foo-1.2.3.tar.gz"
        version "1.2.3"
      end
    }
    let(:old_cache_file) { HOMEBREW_CACHE/"#{formula_name}-1.2.3.tar.gz" }
    let(:new_cache_file) { HOMEBREW_CACHE/"#{formula_name}--1.2.3.tar.gz" }

    before do
      FileUtils.touch old_cache_file
      allow(Formula).to receive(:each).and_yield(f)
    end

    it "moves old files to use double dashes when upgrading from <= 1.7.1" do
      described_class.migrate_cache_entries_to_double_dashes(Version.new("1.7.1"))

      expect(old_cache_file).not_to exist
      expect(new_cache_file).to exist
    end

    context "when the formula name contains dashes" do
      let(:formula_name) { "foo-bar" }

      it "does not introduce extra double dashes when called multiple times" do
        described_class.migrate_cache_entries_to_double_dashes(Version.new("1.7.1"))
        described_class.migrate_cache_entries_to_double_dashes(Version.new("1.7.1"))

        expect(old_cache_file).not_to exist
        expect(new_cache_file).to exist
      end
    end

    it "does not move files if upgrading from > 1.7.1" do
      described_class.migrate_cache_entries_to_double_dashes(Version.new("1.7.2"))

      expect(old_cache_file).to exist
      expect(new_cache_file).not_to exist
    end
  end

  describe "::migrate_cache_entries_to_symlinks" do
    let(:formula_name) { "foo" }
    let(:f) {
      formula formula_name do
        url "https://brew.sh/foo-1.2.3.tar.gz"
        version "1.2.3"
      end
    }
    let(:old_cache_file) { HOMEBREW_CACHE/"#{formula_name}--1.2.3.tar.gz" }
    let(:new_cache_symlink) { HOMEBREW_CACHE/"#{formula_name}--1.2.3.tar.gz" }
    let(:new_cache_file) {
      HOMEBREW_CACHE/"downloads/4a81b0e17a7540b7afe1685671a0a126645117e6c0bc6c66f5ad13b7a5912f80--foo-1.2.3.tar.gz"
    }

    before do
      old_cache_file.dirname.mkpath
      FileUtils.touch old_cache_file
      allow(Formula).to receive(:[]).and_return(f)
    end

    it "moves old files to use symlinks when upgrading from <= 1.7.2" do
      described_class.migrate_cache_entries_to_symlinks(Version.new("1.7.2"))

      expect(old_cache_file).to eq(new_cache_symlink)
      expect(new_cache_symlink).to be_a_symlink
      expect(new_cache_symlink.readlink.to_s)
        .to eq "downloads/4a81b0e17a7540b7afe1685671a0a126645117e6c0bc6c66f5ad13b7a5912f80--foo-1.2.3.tar.gz"
      expect(new_cache_file).to exist
      expect(new_cache_file).to be_a_file
    end

    it "does not move files if upgrading from > 1.7.2" do
      described_class.migrate_cache_entries_to_symlinks(Version.new("1.7.3"))

      expect(old_cache_file).to exist
      expect(new_cache_file).not_to exist
      expect(new_cache_symlink).not_to be_a_symlink
    end
  end
end
