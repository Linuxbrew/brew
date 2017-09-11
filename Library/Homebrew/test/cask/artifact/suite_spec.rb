describe Hbc::Artifact::Suite, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-suite.rb") }

  let(:install_phase) { -> { Hbc::Artifact::Suite.new(cask).install_phase } }

  let(:target_path) { Hbc.appdir.join("Caffeine") }
  let(:source_path) { cask.staged_path.join("Caffeine") }

  before(:each) do
    InstallHelper.install_without_artifacts(cask)
  end

  it "creates a suite containing the expected app" do
    install_phase.call

    expect(target_path.join("Caffeine.app")).to exist
  end

  it "avoids clobbering an existing suite by moving over it" do
    target_path.mkpath

    expect {
      install_phase.call
    }.to raise_error(Hbc::CaskError)

    expect(source_path).to be_a_directory
    expect(target_path).to be_a_directory
    expect(File.identical?(source_path, target_path)).to be false
  end
end
