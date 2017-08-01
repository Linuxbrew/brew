describe Hbc::Artifact::NestedContainer, :cask do
  describe "install" do
    it "extracts the specified paths as containers" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/nested-app.rb").tap do |c|
        InstallHelper.install_without_artifacts(c)
      end

      Hbc::Artifact::NestedContainer.new(cask).install_phase

      expect(cask.staged_path.join("MyNestedApp.app")).to be_a_directory
    end
  end
end
