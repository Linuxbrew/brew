require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Create, :cask do
  around do |example|
    begin
      example.run
    ensure
      %w[new-cask additional-cask another-cask yet-another-cask local-caff].each do |cask|
        FileUtils.rm_f Cask::CaskLoader.path(cask)
      end
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:exec_editor)
  end

  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "opens the editor for the specified Cask" do
    command = described_class.new("new-cask")
    expect(command).to receive(:exec_editor).with(Cask::CaskLoader.path("new-cask"))
    command.run
  end

  it "drops a template down for the specified Cask" do
    described_class.run("new-cask")
    template = File.read(Cask::CaskLoader.path("new-cask"))
    expect(template).to eq <<~RUBY
      cask 'new-cask' do
        version ''
        sha256 ''

        url 'https://'
        name ''
        homepage ''

        app ''
      end
    RUBY
  end

  it "raises an exception when more than one Cask is given" do
    expect {
      described_class.run("additional-cask", "another-cask")
    }.to raise_error(/Only one Cask can be created at a time\./)
  end

  it "raises an exception when the Cask already exists" do
    expect {
      described_class.run("basic-cask")
    }.to raise_error(Cask::CaskAlreadyCreatedError)
  end

  it "allows creating Casks that are substrings of existing Casks" do
    command = described_class.new("local-caff")
    expect(command).to receive(:exec_editor).with(Cask::CaskLoader.path("local-caff"))
    command.run
  end
end
