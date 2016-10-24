require "test_helper"

describe Hbc::Artifact::App do
  describe "activate to alternate target" do
    let(:cask) { Hbc.load("with-alt-target") }

    let(:install_phase) {
      -> { Hbc::Artifact::App.new(cask).install_phase }
    }

    let(:source_path) { cask.staged_path.join("Caffeine.app") }
    let(:target_path) { Hbc.appdir.join("AnotherName.app") }

    before do
      TestHelper.install_without_artifacts(cask)
    end

    it "installs the given apps using the proper target directory" do
      source_path.must_be :directory?
      target_path.wont_be :exist?

      shutup do
        install_phase.call
      end

      target_path.must_be :directory?
      source_path.wont_be :exist?
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

        shutup do
          install_phase.call
        end

        target_path.must_be :directory?
        appsubdir.join("Caffeine.app").wont_be :exist?
      end
    end

    it "only uses apps when they are specified" do
      staged_app_copy = source_path.sub("Caffeine.app", "Caffeine Deluxe.app")
      FileUtils.cp_r source_path, staged_app_copy

      shutup do
        install_phase.call
      end

      target_path.must_be :directory?
      source_path.wont_be :exist?

      Hbc.appdir.join("Caffeine Deluxe.app").wont_be :exist?
      cask.staged_path.join("Caffeine Deluxe.app").must_be :directory?
    end

    it "avoids clobbering an existing app by moving over it" do
      target_path.mkpath

      install_phase.must_output <<-EOS.undent
        ==> It seems there is already an App at '#{target_path}'; not moving.
      EOS

      source_path.must_be :directory?
      target_path.must_be :directory?
      File.identical?(source_path, target_path).must_equal false
    end
  end
end
