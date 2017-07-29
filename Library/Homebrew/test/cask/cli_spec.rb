describe Hbc::CLI, :cask do
  it "lists the taps for Casks that show up in two taps" do
    listing = described_class.nice_listing(%w[
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

  it "ignores the `--language` option, which is handled in `OS::Mac`" do
    cli = described_class.new("--language=en")
    expect(cli).to receive(:detect_command_and_arguments).with(no_args)
    expect(cli).to receive(:exit).with(1)
    cli.run
  end

  context "when no option is specified" do
    it "--binaries is true by default" do
      command = Hbc::CLI::Install.new("some-cask")
      expect(command.binaries?).to be true
    end
  end

  context "::run" do
    let(:noop_command) { double("CLI::Noop") }

    before do
      allow(Hbc).to receive(:init)
      allow(described_class).to receive(:lookup_command).with("noop").and_return(noop_command)
      allow(noop_command).to receive(:run)
    end

    it "passes `--version` along to the subcommand" do
      version_command = double("CLI::Version")
      allow(described_class).to receive(:lookup_command).with("--version").and_return(version_command)
      expect(described_class).to receive(:run_command).with(version_command)
      described_class.run("--version")
    end

    it "prints help output when subcommand receives `--help` flag" do
      command = described_class.new("noop", "--help")
      expect(described_class).to receive(:run_command).with("help", "noop")
      command.run
      expect(command.help?).to eq(true)
    end

    it "respects the env variable when choosing what appdir to create" do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("HOMEBREW_CASK_OPTS").and_return("--appdir=/custom/appdir")
      expect(Hbc).to receive(:appdir=).with(Pathname.new("/custom/appdir"))
      described_class.run("noop")
    end

    it "exits with a status of 1 when something goes wrong" do
      allow(described_class).to receive(:lookup_command).and_raise(Hbc::CaskError)
      command = described_class.new("noop")
      expect(command).to receive(:exit).with(1)
      command.run
    end
  end

  it "provides a help message for all commands" do
    described_class.command_classes.each do |command_class|
      expect(command_class.help).to match(/\w+/), command_class.name
    end
  end
end
