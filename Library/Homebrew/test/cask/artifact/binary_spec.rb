describe Cask::Artifact::Binary, :cask do
  let(:cask) {
    Cask::CaskLoader.load(cask_path("with-binary")).tap do |cask|
      InstallHelper.install_without_artifacts(cask)
    end
  }
  let(:artifacts) { cask.artifacts.select { |a| a.is_a?(described_class) } }
  let(:expected_path) { Cask::Config.global.binarydir.join("binary") }

  after do
    FileUtils.rm expected_path if expected_path.exist?
  end

  context "when --no-binaries is specified" do
    let(:cask) {
      Cask::CaskLoader.load(cask_path("with-binary"))
    }

    it "doesn't link the binary when --no-binaries is specified" do
      Cask::Installer.new(cask, binaries: false).install
      expect(expected_path).not_to exist
    end
  end

  it "links the binary to the proper directory" do
    artifacts.each do |artifact|
      artifact.install_phase(command: NeverSudoSystemCommand, force: false)
    end

    expect(expected_path).to be_a_symlink
    expect(expected_path.readlink).to exist
  end

  context "when the binary is not executable" do
    let(:cask) {
      Cask::CaskLoader.load(cask_path("with-non-executable-binary")).tap do |cask|
        InstallHelper.install_without_artifacts(cask)
      end
    }

    let(:expected_path) { Cask::Config.global.binarydir.join("naked_non_executable") }

    it "makes the binary executable" do
      expect(FileUtils).to receive(:chmod)
        .with("+x", cask.staged_path.join("naked_non_executable")).and_call_original

      artifacts.each do |artifact|
        artifact.install_phase(command: NeverSudoSystemCommand, force: false)
      end

      expect(expected_path).to be_a_symlink
      expect(expected_path.readlink).to be_executable
    end
  end

  it "avoids clobbering an existing binary by linking over it" do
    FileUtils.touch expected_path

    expect {
      artifacts.each do |artifact|
        artifact.install_phase(command: NeverSudoSystemCommand, force: false)
      end
    }.to raise_error(Cask::CaskError)

    expect(expected_path).not_to be :symlink?
  end

  it "clobbers an existing symlink" do
    expected_path.make_symlink("/tmp")

    artifacts.each do |artifact|
      artifact.install_phase(command: NeverSudoSystemCommand, force: false)
    end

    expect(File.readlink(expected_path)).not_to eq("/tmp")
  end

  it "creates parent directory if it doesn't exist" do
    FileUtils.rmdir Cask::Config.global.binarydir

    artifacts.each do |artifact|
      artifact.install_phase(command: NeverSudoSystemCommand, force: false)
    end

    expect(expected_path.exist?).to be true
  end

  context "binary is inside an app package" do
    let(:cask) {
      Cask::CaskLoader.load(cask_path("with-embedded-binary")).tap do |cask|
        InstallHelper.install_without_artifacts(cask)
      end
    }

    it "links the binary to the proper directory" do
      cask.artifacts.select { |a| a.is_a?(Cask::Artifact::App) }.each do |artifact|
        artifact.install_phase(command: NeverSudoSystemCommand, force: false)
      end
      artifacts.each do |artifact|
        artifact.install_phase(command: NeverSudoSystemCommand, force: false)
      end

      expect(expected_path).to be_a_symlink
      expect(expected_path.readlink).to exist
    end
  end
end
