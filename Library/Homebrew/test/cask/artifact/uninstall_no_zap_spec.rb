describe Hbc::Artifact::Zap, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installable.rb") }

  let(:zap_artifact) {
    Hbc::Artifact::Zap.new(cask)
  }

  before(:each) do
    InstallHelper.install_without_artifacts(cask)
  end

  describe "#uninstall_phase" do
    subject { zap_artifact }

    it { is_expected.not_to respond_to(:uninstall_phase) }
  end
end
