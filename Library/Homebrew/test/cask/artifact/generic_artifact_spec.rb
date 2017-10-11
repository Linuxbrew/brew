describe Hbc::Artifact::Artifact, :cask do
  let(:cask) { Hbc::CaskLoader.load(cask_path("with-generic-artifact")) }

  let(:install_phase) {
    lambda do
      cask.artifacts.select { |a| a.is_a?(described_class) }.each do |artifact|
        artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false)
      end
    end
  }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  before do
    InstallHelper.install_without_artifacts(cask)
  end

  context "without target" do
    it "fails to load" do
      expect {
        Hbc::CaskLoader.load(cask_path("with-generic-artifact-no-target"))
      }.to raise_error(Hbc::CaskInvalidError, /target required for Generic Artifact/)
    end
  end

  it "moves the artifact to the proper directory" do
    install_phase.call

    expect(target_path).to be_a_directory
    expect(source_path).not_to exist
  end

  it "avoids clobbering an existing artifact" do
    target_path.mkpath

    expect {
      install_phase.call
    }.to raise_error(Hbc::CaskError)

    expect(source_path).to be_a_directory
    expect(target_path).to be_a_directory
    expect(File.identical?(source_path, target_path)).to be false
  end
end
