require "test_helper"

describe Hbc::Artifact::NestedContainer do
  describe "install" do
    it "extracts the specified paths as containers" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/nested-app.rb").tap do |c|
        TestHelper.install_without_artifacts(c)
      end

      shutup do
        Hbc::Artifact::NestedContainer.new(cask).install_phase
      end

      cask.staged_path.join("MyNestedApp.app").must_be :directory?
    end
  end
end
