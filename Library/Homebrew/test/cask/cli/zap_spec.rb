require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Zap, :cask do
  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "shows an error when a bad Cask is provided" do
    expect { described_class.run("notacask") }
      .to raise_error(Hbc::CaskUnavailableError, /is unavailable/)
  end

  it "can zap and unlink multiple Casks at once" do
    caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))
    transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))

    Hbc::Installer.new(caffeine).install
    Hbc::Installer.new(transmission).install

    expect(caffeine).to be_installed
    expect(transmission).to be_installed

    described_class.run("local-caffeine", "local-transmission")

    expect(caffeine).not_to be_installed
    expect(Hbc.appdir.join("Caffeine.app")).not_to be_a_symlink
    expect(transmission).not_to be_installed
    expect(Hbc.appdir.join("Transmission.app")).not_to be_a_symlink
  end

  # TODO: Explicit test that both zap and uninstall directives get dispatched.
  #       The above tests that implicitly.
  #
  # it "dispatches both uninstall and zap stanzas" do
  #   with_zap = Hbc::CaskLoader.load('with-zap')
  #
  #   Hbc::Installer.new(with_zap).install
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
  #   Hbc::CLI::Zap.run('with-zap')
  #
  #   with_zap.wont_be :installed?
  # end
end
