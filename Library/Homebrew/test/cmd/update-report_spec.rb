require "cmd/update-report"

describe "brew update-report" do
  describe "::migrate_cache_entries_to_double_dashes" do
    let(:legacy_cache_file) { HOMEBREW_CACHE/"foo-1.2.3.tar.gz" }
    let(:renamed_cache_file) { HOMEBREW_CACHE/"foo--1.2.3.tar.gz" }

    before(:each) do
      FileUtils.touch legacy_cache_file
    end

    it "moves old files to use double dashes when upgrading from <= 1.7.1" do
      Homebrew.migrate_cache_entries_to_double_dashes(Version.new("1.7.1"))

      expect(legacy_cache_file).not_to exist
      expect(renamed_cache_file).to exist
    end

    it "does not move files if upgrading from > 1.7.1" do
      Homebrew.migrate_cache_entries_to_double_dashes(Version.new("1.7.2"))

      expect(legacy_cache_file).to exist
      expect(renamed_cache_file).not_to exist
    end
  end
end
