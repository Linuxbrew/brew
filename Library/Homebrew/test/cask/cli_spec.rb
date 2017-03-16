describe Hbc::CLI, :cask do
  it "lists the taps for Casks that show up in two taps" do
    listing = Hbc::CLI.nice_listing(%w[
                                      caskroom/cask/adium
                                      caskroom/cask/google-chrome
                                      passcod/homebrew-cask/adium
                                    ])

    expect(listing).to eq(%w[
                            caskroom/cask/adium
                            google-chrome
                            passcod/cask/adium
                          ])
  end

  context ".process" do
    let(:noop_command) { double("CLI::Noop") }

    before do
      allow(Hbc).to receive(:init)
      allow(described_class).to receive(:lookup_command).with("noop").and_return(noop_command)
      allow(noop_command).to receive(:run)
    end

    around do |example|
      shutup { example.run }
    end

    it "passes `--version` along to the subcommand" do
      version_command = double("CLI::Version")
      allow(described_class).to receive(:lookup_command).with("--version").and_return(version_command)
      expect(described_class).to receive(:run_command).with(version_command)
      described_class.process(["--version"])
    end

    it "prints help output when subcommand receives `--help` flag" do
      begin
        expect(described_class).to receive(:run_command).with("help")
        described_class.process(%w[noop --help])
        expect(Hbc::CLI.help?).to eq(true)
      ensure
        Hbc::CLI.help = false
      end
    end

    it "respects the env variable when choosing what appdir to create" do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("HOMEBREW_CASK_OPTS").and_return("--appdir=/custom/appdir")
      expect(Hbc).to receive(:appdir=).with(Pathname.new("/custom/appdir"))
      described_class.process("noop")
    end

    it "respects the env variable when choosing a non-default Caskroom location" do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("HOMEBREW_CASK_OPTS").and_return("--caskroom=/custom/caskdir")
      expect(Hbc).to receive(:caskroom=).with(Pathname.new("/custom/caskdir"))
      described_class.process("noop")
    end

    it "exits with a status of 1 when something goes wrong" do
      allow(described_class).to receive(:lookup_command).and_raise(Hbc::CaskError)
      expect(described_class).to receive(:exit).with(1)
      described_class.process("noop")
    end
  end

  it "provides a help message for all commands" do
    described_class.command_classes.each do |command_class|
      expect(command_class.help).to match(/\w+/), command_class.name
    end
  end
end
