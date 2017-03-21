require "spec_helper"

describe Hbc::CLI::Zap do
  it "shows an error when a bad Cask is provided" do
    expect {
      Hbc::CLI::Zap.run("notacask")
    }.to raise_error(Hbc::CaskUnavailableError)
  end

  it "can zap and unlink multiple Casks at once" do
    caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
    transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

    shutup do
      Hbc::Installer.new(caffeine).install
      Hbc::Installer.new(transmission).install
    end

    expect(caffeine).to be_installed
    expect(transmission).to be_installed

    shutup do
      Hbc::CLI::Zap.run("--notavalidoption",
                        "local-caffeine", "local-transmission")
    end

    expect(caffeine).not_to be_installed
    expect(Hbc.appdir.join("Caffeine.app")).not_to be_a_symlink
    expect(transmission).not_to be_installed
    expect(Hbc.appdir.join("Transmission.app")).not_to be_a_symlink
  end

  # TODO: Explicit test that both zap and uninstall directives get dispatched.
  #       The above tests that implicitly.
  #
  # it "dispatches both uninstall and zap stanzas" do
  #   with_zap = Hbc.load('with-zap')
  #
  #   shutup do
  #     Hbc::Installer.new(with_zap).install
  #   end
  #
  #   with_zap.must_be :installed?
  #
  #   Hbc::FakeSystemCommand.stubs_command(['/usr/bin/sudo', '-E', '--', '/usr/bin/osascript', '-e', 'tell application "System Events" to count processes whose bundle identifier is "my.fancy.package.app"'], '1')
  #   Hbc::FakeSystemCommand.stubs_command(['/usr/bin/sudo', '-E', '--', '/usr/bin/osascript', '-e', 'tell application id "my.fancy.package.app" to quit'])
  #   Hbc::FakeSystemCommand.stubs_command(['/usr/bin/sudo', '-E', '--', '/usr/bin/osascript', '-e', 'tell application "System Events" to count processes whose bundle identifier is "my.fancy.package.app.from.uninstall"'], '1')
  #   Hbc::FakeSystemCommand.stubs_command(['/usr/bin/sudo', '-E', '--', '/usr/bin/osascript', '-e', 'tell application id "my.fancy.package.app.from.uninstall" to quit'])
  #
  #   Hbc::FakeSystemCommand.expects_command(['/usr/bin/sudo', '-E', '--', with_zap.staged_path.join('MyFancyPkg','FancyUninstaller.tool'), '--please'])
  #   Hbc::FakeSystemCommand.expects_command(['/usr/bin/sudo', '-E', '--', '/bin/rm', '-rf', '--',
  #                                             Pathname.new('~/Library/Preferences/my.fancy.app.plist').expand_path])
  #
  #   shutup do
  #     Hbc::CLI::Zap.run('with-zap')
  #   end
  #   with_zap.wont_be :installed?
  # end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Zap.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Zap.run("--notavalidoption")
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end
end
