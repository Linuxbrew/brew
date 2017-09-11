describe Hbc::CLI::Reinstall, :cask do
  it "displays the reinstallation progress" do
    caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

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

    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed

    Hbc::CLI::Reinstall.run("local-transmission")
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end

  it "allows reinstalling a non installed Cask" do
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).not_to be_installed

    Hbc::CLI::Reinstall.run("local-transmission")
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end
end
