require "cmd/cask"

describe Hbc::DSL::Appcast do
  subject { described_class.new(url, params) }

  let(:url) { "http://example.com" }
  let(:uri) { Hbc::UnderscoreSupportingURI.parse(url) }
  let(:params) { {} }

  describe "#to_s" do
    it "returns the parsed URI string" do
      expect(subject.to_s).to eq("http://example.com")
    end
  end

  describe "#to_yaml" do
    let(:yaml) { [uri, params].to_yaml }

    context "with empty parameters" do
      it "returns an YAML serialized array composed of the URI and parameters" do
        expect(subject.to_yaml).to eq(yaml)
      end
    end

    context "with checkpoint in parameters" do
      let(:params) { { checkpoint: "abc123" } }

      it "returns an YAML serialized array composed of the URI and parameters" do
        expect(subject.to_yaml).to eq(yaml)
      end
    end
  end

  describe "#calculate_checkpoint" do
    before do
      expect(Hbc::SystemCommand).to receive(:run) do |executable, **options|
        expect(executable).to eq "/usr/bin/curl"
        expect(options[:args]).to include(*cmd_args)
        expect(options[:print_stderr]).to be false
        cmd_result
      end
      allow(cmd_result).to receive(:success?).and_return(cmd_success)
      allow(cmd_result).to receive(:stdout).and_return(cmd_stdout)
    end

    context "when server returns a successful HTTP status" do
      let(:cmd_args) { [HOMEBREW_USER_AGENT_FAKE_SAFARI, "--compressed", "--location", "--fail", uri] }
      let(:cmd_result) { double("Hbc::SystemCommand::Result") }
      let(:cmd_success) { true }
      let(:cmd_stdout) { "hello world" }

      it "generates the content digest hash and returns a hash with the command result and the digest hash for the checkpoint" do
        expected_digest = Digest::SHA2.hexdigest(cmd_stdout)
        expected_result = {
          checkpoint: expected_digest,
          command_result: cmd_result,
        }

        expect(subject.calculate_checkpoint).to eq(expected_result)
      end
    end

    context "when server returns a non-successful HTTP status" do
      let(:cmd_args) { [HOMEBREW_USER_AGENT_FAKE_SAFARI, "--compressed", "--location", "--fail", uri] }
      let(:cmd_result) { double("Hbc::SystemCommand::Result") }
      let(:cmd_success) { false }
      let(:cmd_stdout) { "some error message from the server" }

      it "returns a hash with the command result and nil for the checkpoint" do
        expected_result = {
          checkpoint: nil,
          command_result: cmd_result,
        }

        expect(subject.calculate_checkpoint).to eq(expected_result)
      end
    end
  end
end
