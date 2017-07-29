describe Hbc::Artifact::App, :cask do
  describe "activate to alternate target" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-alt-target.rb") }

    let(:install_phase) {
      -> { Hbc::Artifact::App.new(cask).install_phase }
    }

    let(:source_path) { cask.staged_path.join("Caffeine.app") }
    let(:target_path) { Hbc.appdir.join("AnotherName.app") }

    before do
      InstallHelper.install_without_artifacts(cask)
    end

    it "installs the given apps using the proper target directory" do
      expect(source_path).to be_a_directory
      expect(target_path).not_to exist

      install_phase.call

      expect(target_path).to be_a_directory
      expect(source_path).not_to exist
    end

    describe "when app is in a subdirectory" do
      let(:cask) {
        Hbc::Cask.new("subdir") do
          url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
          homepage "http://example.com/local-caffeine"
          version "1.2.3"
          sha256 "67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94"
          app "subdir/Caffeine.app", target: "AnotherName.app"
        end
      }

      it "installs the given apps using the proper target directory" do
        appsubdir = cask.staged_path.join("subdir").tap(&:mkpath)
        FileUtils.mv(source_path, appsubdir)

        install_phase.call

        expect(target_path).to be_a_directory
        expect(appsubdir.join("Caffeine.app")).not_to exist
      end
    end

    it "only uses apps when they are specified" do
      staged_app_copy = source_path.sub("Caffeine.app", "Caffeine Deluxe.app")
      FileUtils.cp_r source_path, staged_app_copy

      install_phase.call

      expect(target_path).to be_a_directory
      expect(source_path).not_to exist

      expect(Hbc.appdir.join("Caffeine Deluxe.app")).not_to exist
      expect(cask.staged_path.join("Caffeine Deluxe.app")).to be_a_directory
    end

    it "avoids clobbering an existing app by moving over it" do
      target_path.mkpath

      expect(install_phase).to raise_error(Hbc::CaskError, "It seems there is already an App at '#{target_path}'.")

      expect(source_path).to be_a_directory
      expect(target_path).to be_a_directory
      expect(File.identical?(source_path, target_path)).to be false
    end
  end
end
