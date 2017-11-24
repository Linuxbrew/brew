require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Upgrade, :cask do
  it_behaves_like "a command that handles invalid options"

  shared_context "Proper Casks" do
    let(:installed) {
      [
        "outdated/local-caffeine",
        "outdated/local-transmission",
        "outdated/auto-updates",
      ]
    }

    before(:example) do
      installed.each { |cask| Hbc::CLI::Install.run(cask) }

      allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
    end
  end

  shared_context "Casks that will fail upon upgrade" do
    let(:installed) {
      [
        "outdated/bad-checksum",
        "outdated/will-fail-if-upgraded",
      ]
    }

    before(:example) do
      installed.each { |cask| Hbc::CLI::Install.run(cask) }

      allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
    end
  end

  describe 'without --greedy it ignores the Casks with "version latest" or "auto_updates true"' do
    include_context "Proper Casks"

    it "and updates all the installed Casks when no token is provided" do
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

    it "and updates only the Casks specified in the command line" do
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

    it 'updates "auto_updates" and "latest" Casks when their tokens are provided in the command line' do
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
      expect(Hbc::CaskLoader.load("auto-updates").versions).to include("2.61")
    end
  end

  describe "with --greedy it checks additional Casks" do
    include_context "Proper Casks"

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

  describe "handles borked upgrades" do
    include_context "Casks that will fail upon upgrade"

    output_reverted = Regexp.new <<~EOS
      Warning: Reverting upgrade for Cask .*
    EOS

    it "restores the old Cask if the upgrade failed" do
      expect(Hbc::CaskLoader.load("will-fail-if-upgraded")).to be_installed
      expect(Hbc.appdir.join("container")).to be_a_file
      expect(Hbc::CaskLoader.load("will-fail-if-upgraded").versions).to include("1.2.2")

      expect {
        described_class.run("will-fail-if-upgraded")
      }.to raise_error(Hbc::CaskError).and output(output_reverted).to_stderr

      expect(Hbc::CaskLoader.load("will-fail-if-upgraded")).to be_installed
      expect(Hbc.appdir.join("container")).to be_a_file
      expect(Hbc::CaskLoader.load("will-fail-if-upgraded").versions).to include("1.2.2")
      expect(Hbc::CaskLoader.load("will-fail-if-upgraded").staged_path).to_not exist
    end

    it "by not restoring the old Cask if the upgrade failed pre-install" do
      expect(Hbc::CaskLoader.load("bad-checksum")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("bad-checksum").versions).to include("1.2.2")

      expect {
        described_class.run("bad-checksum")
      }.to raise_error(Hbc::CaskSha256MismatchError).and (not_to_output output_reverted).to_stderr

      expect(Hbc::CaskLoader.load("bad-checksum")).to be_installed
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
      expect(Hbc::CaskLoader.load("bad-checksum").versions).to include("1.2.2")
      expect(Hbc::CaskLoader.load("bad-checksum").staged_path).to_not exist
    end
  end
end
