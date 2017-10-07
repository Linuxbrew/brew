require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Reinstall, :cask do
  it_behaves_like "a command that handles invalid options"

  it "displays the reinstallation progress" do
    caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))

    Hbc::Installer.new(caffeine).install

    output = Regexp.new <<-EOS.undent
      ==> Downloading file:.*caffeine.zip
      Already downloaded: .*local-caffeine--1.2.3.zip
      ==> Verifying checksum for Cask local-caffeine
      ==> Uninstalling Cask local-caffeine
      ==> Removing App '.*Caffeine.app'.
      ==> Installing Cask local-caffeine
      ==> Moving App 'Caffeine.app' to '.*Caffeine.app'.
      .*local-caffeine was successfully installed!
    EOS

    expect {
      Hbc::CLI::Reinstall.run("local-caffeine")
    }.to output(output).to_stdout
  end

  it "allows reinstalling a Cask" do
    Hbc::CLI::Install.run("local-transmission")

    expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).to be_installed

    Hbc::CLI::Reinstall.run("local-transmission")
    expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).to be_installed
  end

  it "allows reinstalling a non installed Cask" do
    expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).not_to be_installed

    Hbc::CLI::Reinstall.run("local-transmission")
    expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).to be_installed
  end
end
