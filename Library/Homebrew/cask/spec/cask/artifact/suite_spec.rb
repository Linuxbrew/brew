require "spec_helper"

describe Hbc::Artifact::Suite do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-suite.rb") }

  let(:install_phase) { -> { Hbc::Artifact::Suite.new(cask).install_phase } }

  let(:target_path) { Hbc.appdir.join("Caffeine") }
  let(:source_path) { cask.staged_path.join("Caffeine") }

  before(:each) do
    InstallHelper.install_without_artifacts(cask)
  end

  it "moves the suite to the proper directory" do
    skip("flaky test") # FIXME

    shutup do
      install_phase.call
    end

    expect(target_path).to be_a_directory
    expect(target_path).to be_a_symlink
    expect(target_path.readlink).to exist
    expect(source_path).not_to exist
  end

  it "creates a suite containing the expected app" do
    shutup do
      install_phase.call
    end

    expect(target_path.join("Caffeine.app")).to exist
  end

  it "avoids clobbering an existing suite by moving over it" do
    target_path.mkpath

    expect {
      shutup do
        install_phase.call
      end
    }.to raise_error(Hbc::CaskError)

    expect(source_path).to be_a_directory
    expect(target_path).to be_a_directory
    expect(File.identical?(source_path, target_path)).to be false
  end
end
