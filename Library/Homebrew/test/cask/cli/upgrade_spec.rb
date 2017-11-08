require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Upgrade, :cask do
  it_behaves_like "a command that handles invalid options"

  before(:example) do
    installed =
      [
        "outdated/local-caffeine",
        "outdated/local-transmission",
        "outdated/auto-updates",
      ]

    installed.each { |cask| Hbc::CLI::Install.run(cask) }

    allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
  end

  describe 'without --greedy it ignores the Casks with "version latest" or "auto_updates true"' do
    it "updates all the installed Casks when no token is provided" do
      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.2")

      expect(Hbc::CaskLoader.load("local-transmission")).to be_installed
      expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.60")

      described_class.run

      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.3")

      expect(Hbc::CaskLoader.load("local-transmission")).to be_installed
      expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.61")
    end

    it "updates only the Casks specified in the command line" do
      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.2")

      expect(Hbc::CaskLoader.load("local-transmission")).to be_installed
      expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.60")

      described_class.run("local-caffeine")

      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.3")
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to_not include("1.2.2")

      expect(Hbc::CaskLoader.load("local-transmission")).to be_installed
      expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.60")
    end

    it 'ignores "auto_updates" and "latest" Casks even when their tokens are provided in the command line' do
      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.2")

      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.57")

      described_class.run("local-caffeine", "auto-updates")

      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.3")

      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.57")
    end
  end

  describe "with --greedy it checks additional Casks" do
    it 'includes the Casks with "auto_updates true" or "version latest" with --greedy' do
      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.57")

      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.2")

      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.60")

      described_class.run("--greedy")

      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.61")

      expect(Hbc::CaskLoader.load("local-caffeine")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-caffeine").versions).to include("1.2.3")

      expect(Hbc::CaskLoader.load("local-transmission")).to be_installed
      expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("local-transmission").versions).to include("2.61")
    end

    it 'does not include the Casks with "auto_updates true" when the version did not change' do
      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.57")

      described_class.run("auto-updates", "--greedy")

      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.61")

      described_class.run("auto-updates", "--greedy")

      expect(Hbc::CaskLoader.load("auto-updates")).to be_installed
      expect(Hbc.appdir.join("MyFancyApp.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.61")
    end
  end
end
