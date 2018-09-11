describe Cask::Cmd, :cask do
  it "lists the taps for Casks that show up in two taps" do
    listing = described_class.nice_listing(%w[
                                             homebrew/cask/adium
                                             homebrew/cask/google-chrome
                                             passcod/homebrew-cask/adium
                                           ])

    expect(listing).to eq(%w[
                            google-chrome
                            homebrew/cask/adium
                            passcod/cask/adium
                          ])
  end

  it "ignores the `--language` option, which is handled in `OS::Mac`" do
    cli = described_class.new("--language=en")
    expect(cli).to receive(:detect_command_and_arguments).with(no_args)
    cli.run
  end

  context "when given no arguments" do
    it "exits successfully" do
      expect(subject).not_to receive(:exit).with(be_nonzero)
      subject.run
    end
  end

  context "when no option is specified" do
    it "--binaries is true by default" do
      command = Cask::Cmd::Install.new("some-cask")
      expect(command.binaries?).to be true
    end
  end

  context "::run" do
    let(:noop_command) { double("Cmd::Noop") }

    before do
      allow(described_class).to receive(:lookup_command).with("noop").and_return(noop_command)
      allow(noop_command).to receive(:run)
    end

    it "passes `--version` along to the subcommand" do
      version_command = double("Cmd::Version")
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
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HOMEBREW_CASK_OPTS").and_return("--appdir=/custom/appdir")
      allow(Cask::Config.global).to receive(:appdir).and_call_original

      described_class.run("noop")

      expect(Cask::Config.global.appdir).to eq(Pathname.new("/custom/appdir"))
    end

    it "exits with a status of 1 when something goes wrong" do
      allow(described_class).to receive(:lookup_command).and_raise(Cask::CaskError)
      command = described_class.new("noop")
      expect(command).to receive(:exit).with(1)
      command.run
    end
  end

  it "provides a help message for all visible commands" do
    described_class.command_classes.select(&:visible).each do |command_class|
      expect(command_class.help).to match(/\w+/), command_class.name
    end
  end
end
