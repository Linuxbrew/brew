require "test_helper"

describe Hbc::Artifact::Artifact do
  let(:cask) { Hbc.load("with-generic-artifact") }

  let(:install_phase) {
    -> { Hbc::Artifact::Artifact.new(cask).install_phase }
  }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  before do
    TestHelper.install_without_artifacts(cask)
  end

  describe "with no target" do
    let(:cask) { Hbc.load("with-generic-artifact-no-target") }

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

    shutup do
      install_phase.call
    end

    source_path.must_be :directory?
    target_path.must_be :directory?
    File.identical?(source_path, target_path).must_equal false
  end
end
