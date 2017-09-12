require "missing_formula"

describe Homebrew::MissingFormula do
  context "::reason" do
    subject { described_class.reason("gem") }

    it { is_expected.to_not be_nil }
  end

  context "::blacklisted_reason" do
    matcher(:be_blacklisted) do
      match(&Homebrew::MissingFormula.method(:blacklisted_reason))
    end

    context "rubygems" do
      %w[gem rubygem rubygems].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end

    context "latex" do
      %w[latex tex tex-live texlive TexLive].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end

    context "pip" do
      subject { "pip" }

      it { is_expected.to be_blacklisted }
    end

    context "pil" do
      subject { "pil" }

      it { is_expected.to be_blacklisted }
    end

    context "macruby" do
      subject { "MacRuby" }

      it { is_expected.to be_blacklisted }
    end

    context "lzma" do
      %w[lzma liblzma].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end

    context "gtest" do
      %w[gtest googletest google-test].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end

    context "gmock" do
      %w[gmock googlemock google-mock].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end

    context "sshpass" do
      subject { "sshpass" }

      it { is_expected.to be_blacklisted }
    end

    context "gsutil" do
      subject { "gsutil" }

      it { is_expected.to be_blacklisted }
    end

    context "gfortran" do
      subject { "gfortran" }

      it { is_expected.to be_blacklisted }
    end

    context "play" do
      subject { "play" }

      it { is_expected.to be_blacklisted }
    end

    context "haskell-platform" do
      subject { "haskell-platform" }

      it { is_expected.to be_blacklisted }
    end

    context "xcode", :needs_macos do
      %w[xcode Xcode].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
    end
  end

  context "::tap_migration_reason" do
    subject { described_class.tap_migration_reason(formula) }

    before do
      Tap.clear_cache
      tap_path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
      tap_path.mkpath
      (tap_path/"tap_migrations.json").write <<-EOS.undent
        { "migrated-formula": "homebrew/bar" }
      EOS
    end

    context "with a migrated formula" do
      let(:formula) { "migrated-formula" }
      it { is_expected.to_not be_nil }
    end

    context "with a missing formula" do
      let(:formula) { "missing-formula" }
      it { is_expected.to be_nil }
    end
  end

  context "::deleted_reason" do
    subject { described_class.deleted_reason(formula, silent: true) }

    before do
      Tap.clear_cache
      tap_path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
      tap_path.mkpath
      (tap_path/"deleted-formula.rb").write "placeholder"

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
      it { is_expected.to_not be_nil }
    end

    context "with a formula that never existed" do
      let(:formula) { "homebrew/foo/missing-formula" }
      it { is_expected.to be_nil }
    end
  end
end
