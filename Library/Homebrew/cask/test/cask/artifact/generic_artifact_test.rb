require "test_helper"

describe Hbc::Artifact::Artifact do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-generic-artifact.rb") }

  let(:install_phase) {
    -> { Hbc::Artifact::Artifact.new(cask).install_phase }
  }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  before do
    TestHelper.install_without_artifacts(cask)
  end

  describe "with no target" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-generic-artifact-no-target.rb") }

    it "fails to install with no target" do
      install_phase.must_raise Hbc::CaskInvalidError
    end
  end

  it "moves the artifact to the proper directory" do
    shutup do
      install_phase.call
    end

    target_path.must_be :directory?
    source_path.wont_be :exist?
  end

  it "avoids clobbering an existing artifact" do
    target_path.mkpath

    assert_raises Hbc::CaskError do
      shutup do
        install_phase.call
      end
    end

    source_path.must_be :directory?
    target_path.must_be :directory?
    File.identical?(source_path, target_path).must_equal false
  end
end
