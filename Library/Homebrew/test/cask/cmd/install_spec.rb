require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Install, :cask do
  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "displays the installation progress" do
    output = Regexp.new <<~EOS
      ==> Downloading file:.*caffeine.zip
      ==> Verifying SHA-256 checksum for Cask 'local-caffeine'.
      ==> Installing Cask local-caffeine
      ==> Moving App 'Caffeine.app' to '.*Caffeine.app'.
      .*local-caffeine was successfully installed!
    EOS

    expect {
      described_class.run("local-caffeine")
    }.to output(output).to_stdout
  end

  it "allows staging and activation of multiple Casks at once" do
    described_class.run("local-transmission", "local-caffeine")

    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).to be_installed
    expect(Cask::Config.global.appdir.join("Transmission.app")).to be_a_directory
    expect(Cask::CaskLoader.load(cask_path("local-caffeine"))).to be_installed
    expect(Cask::Config.global.appdir.join("Caffeine.app")).to be_a_directory
  end

  it "skips double install (without nuking existing installation)" do
    described_class.run("local-transmission")
    described_class.run("local-transmission")
    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).to be_installed
  end

  it "prints a warning message on double install" do
    described_class.run("local-transmission")

    expect {
      described_class.run("local-transmission")
    }.to output(/Warning: Cask 'local-transmission' is already installed./).to_stderr
  end

  it "allows double install with --force" do
    described_class.run("local-transmission")

    expect {
      expect {
        described_class.run("local-transmission", "--force")
      }.to output(/It seems there is already an App at.*overwriting\./).to_stderr
    }.to output(/local-transmission was successfully installed!/).to_stdout
  end

  it "skips dependencies with --skip-cask-deps" do
    described_class.run("with-depends-on-cask-multiple", "--skip-cask-deps")
    expect(Cask::CaskLoader.load(cask_path("with-depends-on-cask-multiple"))).to be_installed
    expect(Cask::CaskLoader.load(cask_path("local-caffeine"))).not_to be_installed
    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).not_to be_installed
  end

  it "properly handles Casks that are not present" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Cask::CaskUnavailableError)
  end

  it "returns a suggestion for a misspelled Cask" do
    expect {
      described_class.run("localcaffeine")
    }.to raise_error(
      Cask::CaskUnavailableError,
      "Cask 'localcaffeine' is unavailable: No Cask with this name exists. "\
      "Did you mean “local-caffeine”?",
    )
  end

  it "returns multiple suggestions for a Cask fragment" do
    expect {
      described_class.run("local")
    }.to raise_error(
      Cask::CaskUnavailableError,
      "Cask 'local' is unavailable: No Cask with this name exists. " \
      "Did you mean one of these?\nlocal-caffeine\nlocal-transmission\n",
    )
  end
end
