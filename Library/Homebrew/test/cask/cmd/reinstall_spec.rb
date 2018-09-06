require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Reinstall, :cask do
  it_behaves_like "a command that handles invalid options"

  it "displays the reinstallation progress" do
    caffeine = Cask::CaskLoader.load(cask_path("local-caffeine"))

    Cask::Installer.new(caffeine).install

    output = Regexp.new <<~EOS
      ==> Downloading file:.*caffeine.zip
      Already downloaded: .*--caffeine.zip
      ==> Verifying SHA-256 checksum for Cask 'local-caffeine'.
      ==> Uninstalling Cask local-caffeine
      ==> Backing App 'Caffeine.app' up to '.*Caffeine.app'.
      ==> Removing App '.*Caffeine.app'.
      ==> Purging files for version 1.2.3 of Cask local-caffeine
      ==> Installing Cask local-caffeine
      ==> Moving App 'Caffeine.app' to '.*Caffeine.app'.
      .*local-caffeine was successfully installed!
    EOS

    expect {
      Cask::Cmd::Reinstall.run("local-caffeine")
    }.to output(output).to_stdout
  end

  it "allows reinstalling a Cask" do
    Cask::Cmd::Install.run("local-transmission")

    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).to be_installed

    Cask::Cmd::Reinstall.run("local-transmission")
    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).to be_installed
  end

  it "allows reinstalling a non installed Cask" do
    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).not_to be_installed

    Cask::Cmd::Reinstall.run("local-transmission")
    expect(Cask::CaskLoader.load(cask_path("local-transmission"))).to be_installed
  end
end
