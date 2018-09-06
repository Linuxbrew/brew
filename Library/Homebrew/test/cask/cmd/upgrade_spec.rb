require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Upgrade, :cask do
  it_behaves_like "a command that handles invalid options"

  context "successful upgrade" do
    let(:installed) {
      [
        "outdated/local-caffeine",
        "outdated/local-transmission",
        "outdated/auto-updates",
        "outdated/version-latest",
      ]
    }

    before do
      installed.each { |cask| Cask::Cmd::Install.run(cask) }

      allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
    end

    describe 'without --greedy it ignores the Casks with "version latest" or "auto_updates true"' do
      it "updates all the installed Casks when no token is provided" do
        local_caffeine = Cask::CaskLoader.load("local-caffeine")
        local_caffeine_path = Cask::Config.global.appdir.join("Caffeine.app")
        local_transmission = Cask::CaskLoader.load("local-transmission")
        local_transmission_path = Cask::Config.global.appdir.join("Transmission.app")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.2")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.60")

        described_class.run

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.3")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.61")
      end

      it "updates only the Casks specified in the command line" do
        local_caffeine = Cask::CaskLoader.load("local-caffeine")
        local_caffeine_path = Cask::Config.global.appdir.join("Caffeine.app")
        local_transmission = Cask::CaskLoader.load("local-transmission")
        local_transmission_path = Cask::Config.global.appdir.join("Transmission.app")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.2")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.60")

        described_class.run("local-caffeine")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.3")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.60")
      end

      it 'updates "auto_updates" and "latest" Casks when their tokens are provided in the command line' do
        local_caffeine = Cask::CaskLoader.load("local-caffeine")
        local_caffeine_path = Cask::Config.global.appdir.join("Caffeine.app")
        auto_updates = Cask::CaskLoader.load("auto-updates")
        auto_updates_path = Cask::Config.global.appdir.join("MyFancyApp.app")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.2")

        expect(auto_updates).to be_installed
        expect(auto_updates_path).to be_a_directory
        expect(auto_updates.versions).to include("2.57")

        described_class.run("local-caffeine", "auto-updates")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.3")

        expect(auto_updates).to be_installed
        expect(auto_updates_path).to be_a_directory
        expect(auto_updates.versions).to include("2.61")
      end
    end

    describe "with --greedy it checks additional Casks" do
      it 'includes the Casks with "auto_updates true" or "version latest"' do
        local_caffeine = Cask::CaskLoader.load("local-caffeine")
        local_caffeine_path = Cask::Config.global.appdir.join("Caffeine.app")
        auto_updates = Cask::CaskLoader.load("auto-updates")
        auto_updates_path = Cask::Config.global.appdir.join("MyFancyApp.app")
        local_transmission = Cask::CaskLoader.load("local-transmission")
        local_transmission_path = Cask::Config.global.appdir.join("Transmission.app")
        version_latest = Cask::CaskLoader.load("version-latest")
        version_latest_path_1 = Cask::Config.global.appdir.join("Caffeine Mini.app")
        version_latest_path_2 = Cask::Config.global.appdir.join("Caffeine Pro.app")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.2")

        expect(auto_updates).to be_installed
        expect(auto_updates_path).to be_a_directory
        expect(auto_updates.versions).to include("2.57")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.60")

        expect(version_latest).to be_installed
        expect(version_latest_path_1).to be_a_directory
        expect(version_latest_path_2).to be_a_directory
        expect(version_latest.versions).to include("latest")

        described_class.run("--greedy")

        expect(local_caffeine).to be_installed
        expect(local_caffeine_path).to be_a_directory
        expect(local_caffeine.versions).to include("1.2.3")

        expect(auto_updates).to be_installed
        expect(auto_updates_path).to be_a_directory
        expect(auto_updates.versions).to include("2.61")

        expect(local_transmission).to be_installed
        expect(local_transmission_path).to be_a_directory
        expect(local_transmission.versions).to include("2.61")

        expect(version_latest).to be_installed
        expect(version_latest_path_1).to be_a_directory
        expect(version_latest_path_2).to be_a_directory
        expect(version_latest.versions).to include("latest")
      end

      it 'does not include the Casks with "auto_updates true" when the version did not change' do
        cask = Cask::CaskLoader.load("auto-updates")
        cask_path = Cask::Config.global.appdir.join("MyFancyApp.app")

        expect(cask).to be_installed
        expect(cask_path).to be_a_directory
        expect(cask.versions).to include("2.57")

        described_class.run("auto-updates", "--greedy")

        expect(cask).to be_installed
        expect(cask_path).to be_a_directory
        expect(cask.versions).to include("2.61")

        described_class.run("auto-updates", "--greedy")

        expect(cask).to be_installed
        expect(cask_path).to be_a_directory
        expect(cask.versions).to include("2.61")
      end
    end
  end

  context "failed upgrade" do
    let(:installed) {
      [
        "outdated/bad-checksum",
        "outdated/will-fail-if-upgraded",
      ]
    }

    before do
      installed.each { |cask| Cask::Cmd::Install.run(cask) }

      allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
    end

    output_reverted = Regexp.new <<~EOS
      Warning: Reverting upgrade for Cask .*
    EOS

    it "restores the old Cask if the upgrade failed" do
      will_fail_if_upgraded = Cask::CaskLoader.load("will-fail-if-upgraded")
      will_fail_if_upgraded_path = Cask::Config.global.appdir.join("container")

      expect(will_fail_if_upgraded).to be_installed
      expect(will_fail_if_upgraded_path).to be_a_file
      expect(will_fail_if_upgraded.versions).to include("1.2.2")

      expect {
        described_class.run("will-fail-if-upgraded")
      }.to raise_error(Cask::CaskError).and output(output_reverted).to_stderr

      expect(will_fail_if_upgraded).to be_installed
      expect(will_fail_if_upgraded_path).to be_a_file
      expect(will_fail_if_upgraded.versions).to include("1.2.2")
      expect(will_fail_if_upgraded.staged_path).not_to exist
    end

    it "does not restore the old Cask if the upgrade failed pre-install" do
      bad_checksum = Cask::CaskLoader.load("bad-checksum")
      bad_checksum_path = Cask::Config.global.appdir.join("Caffeine.app")

      expect(bad_checksum).to be_installed
      expect(bad_checksum_path).to be_a_directory
      expect(bad_checksum.versions).to include("1.2.2")

      expect {
        described_class.run("bad-checksum")
      }.to raise_error(Cask::CaskSha256MismatchError).and(not_to_output(output_reverted).to_stderr)

      expect(bad_checksum).to be_installed
      expect(bad_checksum_path).to be_a_directory
      expect(bad_checksum.versions).to include("1.2.2")
      expect(bad_checksum.staged_path).not_to exist
    end
  end
end
