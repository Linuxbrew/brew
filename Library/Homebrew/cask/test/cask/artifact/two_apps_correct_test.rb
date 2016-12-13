require "test_helper"

describe Hbc::Artifact::App do
  describe "multiple apps" do
    let(:cask) { Hbc.load("with-two-apps-correct") }

    let(:install_phase) {
      -> { Hbc::Artifact::App.new(cask).install_phase }
    }

    let(:source_path_mini) { cask.staged_path.join("Caffeine Mini.app") }
    let(:target_path_mini) { Hbc.appdir.join("Caffeine Mini.app") }

    let(:source_path_pro) { cask.staged_path.join("Caffeine Pro.app") }
    let(:target_path_pro) { Hbc.appdir.join("Caffeine Pro.app") }

    before do
      TestHelper.install_without_artifacts(cask)
    end

    it "installs both apps using the proper target directory" do
      shutup do
        install_phase.call
      end

      target_path_mini.must_be :directory?
      source_path_mini.wont_be :exist?

      target_path_pro.must_be :directory?
      source_path_pro.wont_be :exist?
    end

    describe "when apps are in a subdirectory" do
      let(:cask) { Hbc.load("with-two-apps-subdir") }

      it "installs both apps using the proper target directory" do
        shutup do
          install_phase.call
        end

        target_path_mini.must_be :directory?
        source_path_mini.wont_be :exist?

        target_path_pro.must_be :directory?
        source_path_pro.wont_be :exist?
      end
    end

    it "only uses apps when they are specified" do
      FileUtils.cp_r source_path_mini, source_path_mini.sub("Caffeine Mini.app", "Caffeine Deluxe.app")

      shutup do
        install_phase.call
      end

      target_path_mini.must_be :directory?
      source_path_mini.wont_be :exist?

      Hbc.appdir.join("Caffeine Deluxe.app").wont_be :exist?
      cask.staged_path.join("Caffeine Deluxe.app").must_be :exist?
    end

    describe "avoids clobbering an existing app" do
      it "when the first app of two already exists" do
        target_path_mini.mkpath

        err = assert_raises Hbc::CaskError do
          install_phase.must_output <<-EOS.undent
            ==> Moving App 'Caffeine Pro.app' to '#{target_path_pro}'
          EOS
        end

        err.message.must_equal("It seems there is already an App at '#{target_path_mini}'.")

        source_path_mini.must_be :directory?
        target_path_mini.must_be :directory?
        File.identical?(source_path_mini, target_path_mini).must_equal false
      end

      it "when the second app of two already exists" do
        target_path_pro.mkpath

        err = assert_raises Hbc::CaskError do
          install_phase.must_output <<-EOS.undent
            ==> Moving App 'Caffeine Mini.app' to '#{target_path_mini}'
          EOS
        end

        err.message.must_equal("It seems there is already an App at '#{target_path_pro}'.")

        source_path_pro.must_be :directory?
        target_path_pro.must_be :directory?
        File.identical?(source_path_pro, target_path_pro).must_equal false
      end
    end
  end
end
