describe "conflicts_with", :cask do
  describe "conflicts_with cask" do
    let(:local_caffeine) {
      Hbc::CaskLoader.load(cask_path("local-caffeine"))
    }

    let(:with_conflicts_with) {
      Hbc::CaskLoader.load(cask_path("with-conflicts-with"))
    }

    it "installs the dependency of a Cask and the Cask itself" do
      Hbc::Installer.new(local_caffeine).install

      expect(local_caffeine).to be_installed

      expect {
        Hbc::Installer.new(with_conflicts_with).install
      }.to raise_error(Hbc::CaskConflictError, "Cask 'with-conflicts-with' conflicts with 'local-caffeine'.")

      expect(with_conflicts_with).not_to be_installed
    end
  end
end
