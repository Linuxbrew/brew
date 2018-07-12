require "missing_formula"

describe Homebrew::MissingFormula do
  describe "::reason" do
    subject { described_class.reason("gem") }

    it { is_expected.not_to be_nil }
  end

  describe "::blacklisted_reason" do
    matcher :be_blacklisted do
      match do |expected|
        described_class.blacklisted_reason(expected)
      end
    end

    specify "RubyGems is blacklisted" do
      expect(%w[gem rubygem rubygems]).to all be_blacklisted
    end

    specify "LaTeX is blacklisted" do
      expect(%w[latex tex tex-live texlive TexLive]).to all be_blacklisted
    end

    specify "pip is blacklisted" do
      expect("pip").to be_blacklisted
    end

    specify "PIL is blacklisted" do
      expect("pil").to be_blacklisted
    end

    specify "MacRuby is blacklisted" do
      expect("MacRuby").to be_blacklisted
    end

    specify "lzma is blacklisted" do
      expect(%w[lzma liblzma]).to all be_blacklisted
    end

    specify "gtest is blacklisted" do
      expect(%w[gtest googletest google-test]).to all be_blacklisted
    end

    specify "gmock is blacklisted" do
      expect(%w[gmock googlemock google-mock]).to all be_blacklisted
    end

    specify "sshpass is blacklisted" do
      expect("sshpass").to be_blacklisted
    end

    specify "gsutil is blacklisted" do
      expect("gsutil").to be_blacklisted
    end

    specify "gfortran is blacklisted" do
      expect("gfortran").to be_blacklisted
    end

    specify "play is blacklisted" do
      expect("play").to be_blacklisted
    end

    specify "haskell-platform is blacklisted" do
      expect("haskell-platform").to be_blacklisted
    end

    specify "mysqldump-secure is blacklisted" do
      expect("mysqldump-secure").to be_blacklisted
    end

    specify "ngrok is blacklisted" do
      expect("ngrok").to be_blacklisted
    end

    specify "Xcode is blacklisted", :needs_macos do
      expect(%w[xcode Xcode]).to all be_blacklisted
    end
  end

  describe "::tap_migration_reason" do
    subject { described_class.tap_migration_reason(formula) }

    before do
      Tap.clear_cache
      tap_path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
      tap_path.mkpath
      (tap_path/"tap_migrations.json").write <<~JSON
        { "migrated-formula": "homebrew/bar" }
      JSON
    end

    context "with a migrated formula" do
      let(:formula) { "migrated-formula" }

      it { is_expected.not_to be_nil }
    end

    context "with a missing formula" do
      let(:formula) { "missing-formula" }

      it { is_expected.to be_nil }
    end
  end

  describe "::deleted_reason" do
    subject { described_class.deleted_reason(formula, silent: true) }

    before do
      Tap.clear_cache
      tap_path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
      tap_path.mkpath
      (tap_path/"deleted-formula.rb").write "placeholder"
      ENV.delete "GIT_AUTHOR_DATE"
      ENV.delete "GIT_COMMITTER_DATE"

      tap_path.cd do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "initial state"
        system "git", "rm", "deleted-formula.rb"
        system "git", "commit", "-m", "delete formula 'deleted-formula'"
      end
    end

    context "with a deleted formula" do
      let(:formula) { "homebrew/foo/deleted-formula" }

      it { is_expected.not_to be_nil }
    end

    context "with a formula that never existed" do
      let(:formula) { "homebrew/foo/missing-formula" }

      it { is_expected.to be_nil }
    end
  end
end
