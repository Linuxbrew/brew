describe Hbc::CLI::Edit, :cask do
  before(:each) do
    allow_any_instance_of(described_class).to receive(:exec_editor)
  end

  it "opens the editor for the specified Cask" do
    command = described_class.new("local-caffeine")
    expect(command).to receive(:exec_editor).with(Hbc::CaskLoader.path("local-caffeine"))
    command.run
  end

  it "raises an error when given more than one argument" do
    expect {
      described_class.new("local-caffeine", "local-transmission")
    }.to raise_error(/Only one Cask can be created at a time./)
  end

  it "raises an exception when the Cask doesnt exist" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Hbc::CaskUnavailableError)
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        described_class.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        described_class.run("--notavalidoption")
      }.to raise_error(/invalid option/)
    end
  end
end
