describe Hbc::Artifact::NestedContainer, :cask do
  describe "install" do
    it "extracts the specified paths as containers" do
      cask = Hbc::CaskLoader.load(cask_path("nested-app")).tap do |c|
        InstallHelper.install_without_artifacts(c)
      end

      cask.artifacts.select { |a| a.is_a?(described_class) }.each do |artifact|
        artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false)
      end

      expect(cask.staged_path.join("MyNestedApp.app")).to be_a_directory
    end
  end
end
