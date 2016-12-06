require "test_helper"

describe Hbc::Artifact::Suite do
  let(:cask) { Hbc.load("with-suite") }

  let(:install_phase) { -> { Hbc::Artifact::Suite.new(cask).install_phase } }

  let(:target_path) { Hbc.appdir.join("Caffeine") }
  let(:source_path) { cask.staged_path.join("Caffeine") }

  before do
    TestHelper.install_without_artifacts(cask)
  end

  it "moves the suite to the proper directory" do
    shutup do
      install_phase.call
    end

    target_path.must_be :directory?
    TestHelper.valid_alias?(target_path).must_equal false
    source_path.wont_be :exist?
  end

  it "creates a suite containing the expected app" do
    shutup do
      install_phase.call
    end

    target_path.join("Caffeine.app").must_be :exist?
  end

  it "avoids clobbering an existing suite by moving over it" do
    target_path.mkpath

    shutup do
      install_phase.call
    end

    source_path.must_be :directory?
    target_path.must_be :directory?
    File.identical?(source_path, target_path).must_equal false
  end
end
