describe Hbc::Artifact::Binary do
  let(:cask) {
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-binary.rb").tap do |cask|
      shutup do
        InstallHelper.install_without_artifacts(cask)
      end
    end
  }
  let(:expected_path) {
    Hbc.binarydir.join("binary")
  }
  before(:each) do
    Hbc.binarydir.mkpath
  end
  after(:each) do
    FileUtils.rm expected_path if expected_path.exist?
  end

  it "links the binary to the proper directory" do
    shutup do
      Hbc::Artifact::Binary.new(cask).install_phase
    end
    expect(expected_path).to be_a_symlink
    expect(expected_path.readlink).to exist
  end

  it "avoids clobbering an existing binary by linking over it" do
    FileUtils.touch expected_path

    expect {
      shutup do
        Hbc::Artifact::Binary.new(cask).install_phase
      end
    }.to raise_error(Hbc::CaskError)

    expect(expected_path).not_to be :symlink?
  end

  it "clobbers an existing symlink" do
    expected_path.make_symlink("/tmp")

    shutup do
      Hbc::Artifact::Binary.new(cask).install_phase
    end

    expect(File.readlink(expected_path)).not_to eq("/tmp")
  end

  it "respects --no-binaries flag" do
    Hbc.no_binaries = true

    shutup do
      Hbc::Artifact::Binary.new(cask).install_phase
    end

    expect(expected_path.exist?).to be false

    Hbc.no_binaries = false
  end

  it "creates parent directory if it doesn't exist" do
    FileUtils.rmdir Hbc.binarydir

    shutup do
      Hbc::Artifact::Binary.new(cask).install_phase
    end

    expect(expected_path.exist?).to be true
  end

  context "binary is inside an app package" do
    let(:cask) {
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-embedded-binary.rb").tap do |cask|
        shutup do
          InstallHelper.install_without_artifacts(cask)
        end
      end
    }

    it "links the binary to the proper directory" do
      shutup do
        Hbc::Artifact::App.new(cask).install_phase
        Hbc::Artifact::Binary.new(cask).install_phase
      end

      expect(expected_path).to be_a_symlink
      expect(expected_path.readlink).to exist
    end
  end
end
