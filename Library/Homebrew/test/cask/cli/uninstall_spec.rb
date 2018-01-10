require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Uninstall, :cask do
  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "displays the uninstallation progress" do
    caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))

    Hbc::Installer.new(caffeine).install

    output = Regexp.new <<~EOS
      ==> Uninstalling Cask local-caffeine
      ==> Moving App 'Caffeine.app' back to '.*Caffeine.app'.
      ==> Purging files for version 1.2.3 of Cask local-caffeine
    EOS

    expect {
      described_class.run("local-caffeine")
    }.to output(output).to_stdout
  end

  it "shows an error when a bad Cask is provided" do
    expect { described_class.run("notacask") }
      .to raise_error(Hbc::CaskUnavailableError, /is unavailable/)
  end

  it "shows an error when a Cask is provided that's not installed" do
    expect { described_class.run("local-caffeine") }
    .to raise_error(Hbc::CaskNotInstalledError, /is not installed/)
  end

  it "tries anyway on a non-present Cask when --force is given" do
    expect {
      described_class.run("local-caffeine", "--force")
    }.not_to raise_error
  end

  it "can uninstall and unlink multiple Casks at once" do
    caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))
    transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))

    Hbc::Installer.new(caffeine).install
    Hbc::Installer.new(transmission).install

    expect(caffeine).to be_installed
    expect(transmission).to be_installed

    described_class.run("local-caffeine", "local-transmission")

    expect(caffeine).not_to be_installed
    expect(Hbc.appdir.join("Transmission.app")).not_to exist
    expect(transmission).not_to be_installed
    expect(Hbc.appdir.join("Caffeine.app")).not_to exist
  end

  it "calls `uninstall` before removing artifacts" do
    cask = Hbc::CaskLoader.load(cask_path("with-uninstall-script-app"))

    Hbc::Installer.new(cask).install

    expect(cask).to be_installed
    expect(Hbc.appdir.join("MyFancyApp.app")).to exist

    expect {
      described_class.run("with-uninstall-script-app")
    }.not_to raise_error

    expect(cask).not_to be_installed
    expect(Hbc.appdir.join("MyFancyApp.app")).not_to exist
  end

  it "can uninstall Casks when the uninstall script is missing, but only when using `--force`" do
    cask = Hbc::CaskLoader.load(cask_path("with-uninstall-script-app"))

    Hbc::Installer.new(cask).install

    expect(cask).to be_installed

    Hbc.appdir.join("MyFancyApp.app").rmtree

    expect { described_class.run("with-uninstall-script-app") }
    .to raise_error(Hbc::CaskError, /uninstall script .* does not exist/)

    expect(cask).to be_installed

    expect {
      described_class.run("with-uninstall-script-app", "--force")
    }.not_to raise_error

    expect(cask).not_to be_installed
  end

  describe "when multiple versions of a cask are installed" do
    let(:token) { "versioned-cask" }
    let(:first_installed_version) { "1.2.3" }
    let(:last_installed_version) { "4.5.6" }
    let(:timestamped_versions) {
      [
        [first_installed_version, "123000"],
        [last_installed_version,  "456000"],
      ]
    }
    let(:caskroom_path) { Hbc.caskroom.join(token).tap(&:mkpath) }

    before(:each) do
      timestamped_versions.each do |timestamped_version|
        caskroom_path.join(".metadata", *timestamped_version, "Casks").tap(&:mkpath)
                     .join("#{token}.rb").open("w") do |caskfile|
                       caskfile.puts <<~EOS
                         cask '#{token}' do
                           version '#{timestamped_version[0]}'
                         end
                       EOS
                     end
        caskroom_path.join(timestamped_version[0]).mkpath
      end
    end

    it "uninstalls one version at a time" do
      described_class.run("versioned-cask")

      expect(caskroom_path.join(first_installed_version)).to exist
      expect(caskroom_path.join(last_installed_version)).not_to exist
      expect(caskroom_path).to exist

      described_class.run("versioned-cask")

      expect(caskroom_path.join(first_installed_version)).not_to exist
      expect(caskroom_path).not_to exist
    end

    it "displays a message when versions remain installed" do
      expect {
        expect {
          described_class.run("versioned-cask")
        }.not_to output.to_stderr
      }.to output(/#{token} #{first_installed_version} is still installed./).to_stdout
    end
  end

  describe "when Casks in Taps have been renamed or removed" do
    let(:app) { Hbc.appdir.join("ive-been-renamed.app") }
    let(:caskroom_path) { Hbc.caskroom.join("ive-been-renamed").tap(&:mkpath) }
    let(:saved_caskfile) { caskroom_path.join(".metadata", "latest", "timestamp", "Casks").join("ive-been-renamed.rb") }

    before do
      app.tap(&:mkpath)
         .join("Contents").tap(&:mkpath)
         .join("Info.plist").tap(&FileUtils.method(:touch))

      caskroom_path.mkpath

      saved_caskfile.dirname.mkpath

      IO.write saved_caskfile, <<~EOS
        cask 'ive-been-renamed' do
          version :latest

          app 'ive-been-renamed.app'
        end
      EOS
    end

    it "can still uninstall those Casks" do
      described_class.run("ive-been-renamed")

      expect(app).not_to exist
      expect(caskroom_path).not_to exist
    end
  end
end
