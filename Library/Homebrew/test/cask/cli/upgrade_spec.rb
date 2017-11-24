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
      local_caffeine = Hbc::CaskLoader.load("local-caffeine")
      local_caffeine_route = Hbc.appdir.join("Caffeine.app")
      local_transmission = Hbc::CaskLoader.load("local-transmission")
      local_transmission_route = Hbc.appdir.join("Transmission.app")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.2")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.60")

      described_class.run

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.3")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.61")
    end

    it "and updates only the Casks specified in the command line" do
      local_caffeine = Hbc::CaskLoader.load("local-caffeine")
      local_caffeine_route = Hbc.appdir.join("Caffeine.app")
      local_transmission = Hbc::CaskLoader.load("local-transmission")
      local_transmission_route = Hbc.appdir.join("Transmission.app")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.2")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.60")

      described_class.run("local-caffeine")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.3")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.60")
    end

    it 'updates "auto_updates" and "latest" Casks when their tokens are provided in the command line' do
      local_caffeine = Hbc::CaskLoader.load("local-caffeine")
      local_caffeine_route = Hbc.appdir.join("Caffeine.app")
      auto_updates = Hbc::CaskLoader.load("auto-updates")
      auto_updates_path = Hbc.appdir.join("MyFancyApp.app")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.2")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.57")

      described_class.run("local-caffeine", "auto-updates")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.3")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.61")
    end
  end

  describe "with --greedy it checks additional Casks" do
    include_context "Proper Casks"

    it 'includes the Casks with "auto_updates true" or "version latest" with --greedy' do
      local_caffeine = Hbc::CaskLoader.load("local-caffeine")
      local_caffeine_route = Hbc.appdir.join("Caffeine.app")
      auto_updates = Hbc::CaskLoader.load("auto-updates")
      auto_updates_path = Hbc.appdir.join("MyFancyApp.app")
      local_transmission = Hbc::CaskLoader.load("local-transmission")
      local_transmission_route = Hbc.appdir.join("Transmission.app")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.2")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.57")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.60")

      described_class.run("--greedy")

      expect(local_caffeine).to be_installed
      expect(local_caffeine_route).to be_a_directory
      expect(local_caffeine.versions).to include("1.2.3")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.61")

      expect(local_transmission).to be_installed
      expect(local_transmission_route).to be_a_directory
      expect(local_transmission.versions).to include("2.61")
    end

    it 'does not include the Casks with "auto_updates true" when the version did not change' do
      auto_updates = Hbc::CaskLoader.load("auto-updates")
      auto_updates_path = Hbc.appdir.join("MyFancyApp.app")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.57")

      described_class.run("auto-updates", "--greedy")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.61")

      described_class.run("auto-updates", "--greedy")

      expect(auto_updates).to be_installed
      expect(auto_updates_path).to be_a_directory
      expect(auto_updates.versions).to include("2.61")
    end
  end

  describe "handles borked upgrades" do
    include_context "Casks that will fail upon upgrade"

    output_reverted = Regexp.new <<~EOS
      Warning: Reverting upgrade for Cask .*
    EOS

    it "restores the old Cask if the upgrade failed" do
      will_fail_if_upgraded = Hbc::CaskLoader.load("will-fail-if-upgraded")
      will_fail_if_upgraded_path = Hbc.appdir.join("container")

      expect(will_fail_if_upgraded).to be_installed
      expect(will_fail_if_upgraded_path).to be_a_file
      expect(will_fail_if_upgraded.versions).to include("1.2.2")

      expect {
        described_class.run("will-fail-if-upgraded")
      }.to raise_error(Hbc::CaskError).and output(output_reverted).to_stderr

      expect(will_fail_if_upgraded).to be_installed
      expect(will_fail_if_upgraded_path).to be_a_file
      expect(will_fail_if_upgraded.versions).to include("1.2.2")
      expect(will_fail_if_upgraded.staged_path).to_not exist
    end

    it "by not restoring the old Cask if the upgrade failed pre-install" do
      bad_checksum = Hbc::CaskLoader.load("bad-checksum")
      bad_checksum_path = Hbc.appdir.join("Caffeine.app")

      expect(bad_checksum).to be_installed
      expect(bad_checksum_path).to be_a_directory
      expect(bad_checksum.versions).to include("1.2.2")

      expect {
        described_class.run("bad-checksum")
      }.to raise_error(Hbc::CaskSha256MismatchError).and(not_to_output(output_reverted).to_stderr)

      expect(bad_checksum).to be_installed
      expect(bad_checksum_path).to be_a_directory
      expect(bad_checksum.versions).to include("1.2.2")
      expect(bad_checksum.staged_path).to_not exist
    end
  end
end
