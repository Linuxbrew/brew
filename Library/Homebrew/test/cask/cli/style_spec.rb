require "open3"
require "rubygems"

describe Hbc::CLI::Style, :cask do
  let(:args) { [] }
  let(:cli) { described_class.new(*args) }

  around(&:run)

  describe "#run" do
    subject { cli.run }

    before do
      allow(cli).to receive_messages(install_rubocop: nil,
                                     system:          nil,
                                     rubocop_args:    nil,
                                     cask_paths:      nil)
      allow($CHILD_STATUS).to receive(:success?).and_return(success)
    end

    context "when rubocop succeeds" do
      let(:success) { true }
      it { is_expected.to be_truthy }
    end

    context "when rubocop fails" do
      let(:success) { false }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskError)
      end
    end
  end

  describe "#install_rubocop" do
    subject { cli.install_rubocop }

    context "when installation succeeds" do
      before do
        allow(Homebrew).to receive(:install_gem_setup_path!)
      end

      it "exits successfully" do
        expect { subject }.not_to raise_error
      end
    end

    context "when installation fails" do
      before do
        allow(Homebrew).to receive(:install_gem_setup_path!).and_raise(SystemExit)
      end

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskError)
      end
    end

    specify "`rubocop-cask` supports `HOMEBREW_RUBOCOP_VERSION`", :needs_network do
      stdout, status = Open3.capture2("gem", "dependency", "rubocop-cask", "--version", HOMEBREW_RUBOCOP_CASK_VERSION, "--pipe", "--remote")

      expect(status).to be_a_success

      requirement = Gem::Requirement.new(stdout.scan(/rubocop --version '(.*)'/).flatten.first)
      version = Gem::Version.new(HOMEBREW_RUBOCOP_VERSION)

      expect(requirement).not_to be_none
      expect(requirement).to be_satisfied_by(version)
    end
  end

  describe "#cask_paths" do
    subject { cli.cask_paths }

    before do
      allow(cli).to receive(:args).and_return(tokens)
    end

    context "when no cask tokens are given" do
      let(:tokens) { [] }

      before do
        allow(Hbc).to receive(:all_tapped_cask_dirs).and_return(%w[Casks MoreCasks])
      end

      it { is_expected.to eq(%w[Casks MoreCasks]) }
    end

    context "when at least one cask token is a path that exists" do
      let(:tokens) { ["adium", "Casks/dropbox.rb"] }
      before do
        allow(File).to receive(:exist?).and_return(false, true)
      end

      it "treats all tokens as paths" do
        expect(subject).to eq(tokens)
      end
    end

    context "when no cask tokens are paths that exist" do
      let(:tokens) { %w[adium dropbox] }
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "tries to find paths for all tokens" do
        expect(Hbc::CaskLoader).to receive(:load).twice.and_return(double("cask", sourcefile_path: nil))
        subject
      end
    end
  end

  describe "#rubocop_args" do
    subject { cli.rubocop_args }

    before do
      allow(cli).to receive(:fix?).and_return(fix)
    end

    context "when fix? is true" do
      let(:fix) { true }
      it { is_expected.to include("--auto-correct") }
    end

    context "when fix? is false" do
      let(:fix) { false }
      it { is_expected.not_to include("--auto-correct") }
    end
  end

  describe "#default_args" do
    subject { cli.default_args }

    it { is_expected.to include("--require", "rubocop-cask", "--format", "simple", "--force-exclusion") }
  end

  describe "#autocorrect_args" do
    subject { cli.autocorrect_args }
    let(:default_args) { ["--format", "simple"] }

    it "should add --auto-correct to default args" do
      allow(cli).to receive(:default_args).and_return(default_args)
      expect(subject).to include("--auto-correct", *default_args)
    end
  end
end
