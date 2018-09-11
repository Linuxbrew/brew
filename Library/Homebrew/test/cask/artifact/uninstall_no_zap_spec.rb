describe Cask::Artifact::Zap, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("with-installable")) }

  let(:zap_artifact) {
    cask.artifacts.find { |a| a.is_a?(described_class) }
  }

  before do
    InstallHelper.install_without_artifacts(cask)
  end

  describe "#uninstall_phase" do
    subject { zap_artifact }

    it { is_expected.not_to respond_to(:uninstall_phase) }
  end
end
