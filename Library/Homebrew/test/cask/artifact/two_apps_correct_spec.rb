describe Hbc::Artifact::App, :cask do
  describe "multiple apps" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-two-apps-correct.rb") }

    let(:install_phase) {
      -> { Hbc::Artifact::App.new(cask).install_phase }
    }

    let(:source_path_mini) { cask.staged_path.join("Caffeine Mini.app") }
    let(:target_path_mini) { Hbc.appdir.join("Caffeine Mini.app") }

    let(:source_path_pro) { cask.staged_path.join("Caffeine Pro.app") }
    let(:target_path_pro) { Hbc.appdir.join("Caffeine Pro.app") }

    before(:each) do
      InstallHelper.install_without_artifacts(cask)
    end

    it "installs both apps using the proper target directory" do
      install_phase.call

      expect(target_path_mini).to be_a_directory
      expect(source_path_mini).not_to exist

      expect(target_path_pro).to be_a_directory
      expect(source_path_pro).not_to exist
    end

    describe "when apps are in a subdirectory" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-two-apps-subdir.rb") }

      it "installs both apps using the proper target directory" do
        install_phase.call

        expect(target_path_mini).to be_a_directory
        expect(source_path_mini).not_to exist

        expect(target_path_pro).to be_a_directory
        expect(source_path_pro).not_to exist
      end
    end

    it "only uses apps when they are specified" do
      FileUtils.cp_r source_path_mini, source_path_mini.sub("Caffeine Mini.app", "Caffeine Deluxe.app")

      install_phase.call

      expect(target_path_mini).to be_a_directory
      expect(source_path_mini).not_to exist

      expect(Hbc.appdir.join("Caffeine Deluxe.app")).not_to exist
      expect(cask.staged_path.join("Caffeine Deluxe.app")).to exist
    end

    describe "avoids clobbering an existing app" do
      it "when the first app of two already exists" do
        target_path_mini.mkpath

        expect {
          expect(install_phase).to output(<<-EOS.undent).to_stdout
            ==> Moving App 'Caffeine Pro.app' to '#{target_path_pro}'
          EOS
        }.to raise_error(Hbc::CaskError, "It seems there is already an App at '#{target_path_mini}'.")

        expect(source_path_mini).to be_a_directory
        expect(target_path_mini).to be_a_directory
        expect(File.identical?(source_path_mini, target_path_mini)).to be false
      end

      it "when the second app of two already exists" do
        target_path_pro.mkpath

        expect {
          expect(install_phase).to output(<<-EOS.undent).to_stdout
            ==> Moving App 'Caffeine Mini.app' to '#{target_path_mini}'
          EOS
        }.to raise_error(Hbc::CaskError, "It seems there is already an App at '#{target_path_pro}'.")

        expect(source_path_pro).to be_a_directory
        expect(target_path_pro).to be_a_directory
        expect(File.identical?(source_path_pro, target_path_pro)).to be false
      end
    end
  end
end
