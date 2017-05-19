describe Hbc::CLI::Create, :cask do
  around(:each) do |example|
    begin
      example.run
    ensure
      %w[new-cask additional-cask another-cask yet-another-cask local-caff].each do |cask|
        FileUtils.rm_f Hbc::CaskLoader.path(cask)
      end
    end
  end

  before(:each) do
    allow_any_instance_of(described_class).to receive(:exec_editor)
  end

  it "opens the editor for the specified Cask" do
    command = described_class.new("new-cask")
    expect(command).to receive(:exec_editor).with(Hbc::CaskLoader.path("new-cask"))
    command.run
  end

  it "drops a template down for the specified Cask" do
    described_class.run("new-cask")
    template = File.read(Hbc::CaskLoader.path("new-cask"))
    expect(template).to eq <<-EOS.undent
      cask 'new-cask' do
        version ''
        sha256 ''

        url 'https://'
        name ''
        homepage ''

        app ''
      end
    EOS
  end

  it "throws away additional Cask arguments and uses the first" do
    command = described_class.new("additional-cask", "another-cask")
    expect(command).to receive(:exec_editor).with(Hbc::CaskLoader.path("additional-cask"))
    command.run
  end

  it "throws away stray options" do
    command = described_class.new("--notavalidoption", "yet-another-cask")
    expect(command).to receive(:exec_editor).with(Hbc::CaskLoader.path("yet-another-cask"))
    command.run
  end

  it "raises an exception when the Cask already exists" do
    expect {
      described_class.run("basic-cask")
    }.to raise_error(Hbc::CaskAlreadyCreatedError)
  end

  it "allows creating Casks that are substrings of existing Casks" do
    command = described_class.new("local-caff")
    expect(command).to receive(:exec_editor).with(Hbc::CaskLoader.path("local-caff"))
    command.run
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
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end
end
