describe Hbc::Artifact::NestedContainer, :cask do
  describe "install" do
    it "extracts the specified paths as containers" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/nested-app.rb").tap do |c|
        InstallHelper.install_without_artifacts(c)
      end

      cask.artifacts.select { |a| a.is_a?(described_class) }.each do |artifact|
        artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false)
      end

      expect(cask.staged_path.join("MyNestedApp.app")).to be_a_directory
    end
  end
end
