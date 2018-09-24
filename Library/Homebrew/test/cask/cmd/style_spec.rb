require "open3"
require "rubygems"

require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Style, :cask do
  let(:args) { [] }
  let(:cli) { described_class.new(*args) }

  it_behaves_like "a command that handles invalid options"

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

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when rubocop fails" do
      let(:success) { false }

      it "raises an error" do
        expect { subject }.to raise_error(Cask::CaskError)
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
        expect { subject }.to raise_error(Cask::CaskError)
      end
    end

    specify "`rubocop-cask` supports `HOMEBREW_RUBOCOP_VERSION`", :needs_network do
      stdout, status = Open3.capture2(
        "gem", "dependency", "rubocop-cask",
        "--version", HOMEBREW_RUBOCOP_CASK_VERSION, "--pipe", "--remote"
      )

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

      matcher :a_path_ending_with do |end_string|
        match do |actual|
          expect(actual.to_s).to end_with(end_string)
        end
      end

      it {
        expect(subject).to contain_exactly(a_path_ending_with("/homebrew/homebrew-cask/Casks"),
                                       a_path_ending_with("/third-party/homebrew-tap/Casks"))
      }
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
        expect(Cask::CaskLoader).to receive(:load).twice.and_return(double("cask", sourcefile_path: nil))
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

    it { is_expected.to include("--require", "rubocop-cask", "--format", "simple") }
  end

  describe "#autocorrect_args" do
    subject { cli.autocorrect_args }

    let(:default_args) { ["--format", "simple"] }

    it "adds --auto-correct to default args" do
      allow(cli).to receive(:default_args).and_return(default_args)
      expect(subject).to include("--auto-correct", *default_args)
    end
  end
end
