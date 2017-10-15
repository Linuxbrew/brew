describe Hbc::Artifact::Artifact, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-generic-artifact.rb") }

  let(:install_phase) {
    -> { described_class.for_cask(cask).each { |artifact| artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false) } }
  }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  before do
    InstallHelper.install_without_artifacts(cask)
  end

  context "without target" do
    it "fails to load" do
      expect {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-generic-artifact-no-target.rb")
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
