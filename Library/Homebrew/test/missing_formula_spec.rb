require "missing_formula"

describe Homebrew::MissingFormula do
  context ".reason" do
    subject { described_class.reason("gem") }

    it { is_expected.to_not be_nil }
  end

  context ".blacklisted_reason" do
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

    context "clojure" do
      subject { "clojure" }

      it { is_expected.to be_blacklisted }
    end

    context "osmium" do
      %w[osmium Osmium].each do |s|
        subject { s }

        it { is_expected.to be_blacklisted }
      end
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
end
