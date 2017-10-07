describe Hbc::Artifact::NestedContainer, :cask do
  describe "install" do
    it "extracts the specified paths as containers" do
      cask = Hbc::CaskLoader.load(cask_path("nested-app")).tap do |c|
        InstallHelper.install_without_artifacts(c)
      end

      described_class.for_cask(cask)
        .each { |artifact| artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false) }

      expect(cask.staged_path.join("MyNestedApp.app")).to be_a_directory
    end
  end
end
