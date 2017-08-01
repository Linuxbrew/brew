describe Hbc::Artifact::Binary, :cask do
  let(:cask) {
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-binary.rb").tap do |cask|
      InstallHelper.install_without_artifacts(cask)
    end
  }
  let(:expected_path) { Hbc.binarydir.join("binary") }

  before(:each) do
    Hbc.binarydir.mkpath
  end

  after(:each) do
    FileUtils.rm expected_path if expected_path.exist?
  end

  context "when --no-binaries is specified" do
    let(:cask) {
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-binary.rb")
    }

    it "doesn't link the binary when --no-binaries is specified" do
      Hbc::Installer.new(cask, binaries: false).install
      expect(expected_path).not_to exist
    end
  end

  it "links the binary to the proper directory" do
    Hbc::Artifact::Binary.new(cask).install_phase

    expect(expected_path).to be_a_symlink
    expect(expected_path.readlink).to exist
  end

  context "when the binary is not executable" do
    let(:cask) {
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-non-executable-binary.rb").tap do |cask|
        InstallHelper.install_without_artifacts(cask)
      end
    }

    let(:expected_path) { Hbc.binarydir.join("naked_non_executable") }

    it "makes the binary executable" do
      expect(FileUtils).to receive(:chmod)
        .with("+x", cask.staged_path.join("naked_non_executable")).and_call_original

      Hbc::Artifact::Binary.new(cask).install_phase

      expect(expected_path).to be_a_symlink
      expect(expected_path.readlink).to be_executable
    end
  end

  it "avoids clobbering an existing binary by linking over it" do
    FileUtils.touch expected_path

    expect {
      Hbc::Artifact::Binary.new(cask).install_phase
    }.to raise_error(Hbc::CaskError)

    expect(expected_path).not_to be :symlink?
  end

  it "clobbers an existing symlink" do
    expected_path.make_symlink("/tmp")

    Hbc::Artifact::Binary.new(cask).install_phase

    expect(File.readlink(expected_path)).not_to eq("/tmp")
  end

  it "creates parent directory if it doesn't exist" do
    FileUtils.rmdir Hbc.binarydir

    Hbc::Artifact::Binary.new(cask).install_phase

    expect(expected_path.exist?).to be true
  end

  context "binary is inside an app package" do
    let(:cask) {
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-embedded-binary.rb").tap do |cask|
        InstallHelper.install_without_artifacts(cask)
      end
    }

    it "links the binary to the proper directory" do
      Hbc::Artifact::App.new(cask).install_phase
      Hbc::Artifact::Binary.new(cask).install_phase

      expect(expected_path).to be_a_symlink
      expect(expected_path.readlink).to exist
    end
  end
end
