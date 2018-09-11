require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Edit, :cask do
  before do
    allow_any_instance_of(described_class).to receive(:exec_editor)
  end

  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "opens the editor for the specified Cask" do
    command = described_class.new("local-caffeine")
    expect(command).to receive(:exec_editor).with(Cask::CaskLoader.path("local-caffeine"))
    command.run
  end

  it "raises an error when given more than one argument" do
    expect {
      described_class.new("local-caffeine", "local-transmission")
    }.to raise_error(/Only one Cask can be edited at a time\./)
  end

  it "raises an exception when the Cask doesnt exist" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Cask::CaskUnavailableError)
  end
end
