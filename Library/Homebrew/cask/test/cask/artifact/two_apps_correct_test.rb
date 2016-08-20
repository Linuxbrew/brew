require "test_helper"

describe Hbc::Artifact::App do
  let(:local_two_apps_caffeine) {
    Hbc.load("with-two-apps-correct").tap do |cask|
      TestHelper.install_without_artifacts(cask)
    end
  }

  let(:local_two_apps_subdir) {
    Hbc.load("with-two-apps-subdir").tap do |cask|
      TestHelper.install_without_artifacts(cask)
    end
  }

  describe "multiple apps" do
    it "installs both apps using the proper target directory" do
      cask = local_two_apps_caffeine

      shutup do
        Hbc::Artifact::App.new(cask).install_phase
      end

      File.ftype(Hbc.appdir.join("Caffeine Mini.app")).must_equal "directory"
      File.exist?(cask.staged_path.join("Caffeine Mini.app")).must_equal false

      File.ftype(Hbc.appdir.join("Caffeine Pro.app")).must_equal "directory"
      File.exist?(cask.staged_path.join("Caffeine Pro.app")).must_equal false
    end

    it "works with an application in a subdir" do
      cask = local_two_apps_subdir
      TestHelper.install_without_artifacts(cask)

      shutup do
        Hbc::Artifact::App.new(cask).install_phase
      end

      File.ftype(Hbc.appdir.join("Caffeine Mini.app")).must_equal "directory"
      File.exist?(cask.staged_path.join("Caffeine Mini.app")).must_equal false

      File.ftype(Hbc.appdir.join("Caffeine Pro.app")).must_equal "directory"
      File.exist?(cask.staged_path.join("Caffeine Pro.app")).must_equal false
    end

    it "only uses apps when they are specified" do
      cask = local_two_apps_caffeine

      app_path = cask.staged_path.join("Caffeine Mini.app")
      FileUtils.cp_r app_path, app_path.sub("Caffeine Mini.app", "Caffeine Deluxe.app")

      shutup do
        Hbc::Artifact::App.new(cask).install_phase
      end

      File.ftype(Hbc.appdir.join("Caffeine Mini.app")).must_equal "directory"
      File.exist?(cask.staged_path.join("Caffeine Mini.app")).must_equal false

      File.exist?(Hbc.appdir.join("Caffeine Deluxe.app")).must_equal false
      File.exist?(cask.staged_path.join("Caffeine Deluxe.app")).must_equal true
    end


    describe "avoids clobbering an existing app" do
      let(:cask) { local_two_apps_caffeine }

      it "when the first app of two already exists" do
        Hbc.appdir.join("Caffeine Mini.app").mkpath

        TestHelper.must_output(self, lambda {
          Hbc::Artifact::App.new(cask).install_phase
        }, <<-EOS.undent.chomp)
             ==> It seems there is already an App at '#{Hbc.appdir.join('Caffeine Mini.app')}'; not moving.
             ==> Moving App 'Caffeine Pro.app' to '#{Hbc.appdir.join('Caffeine Pro.app')}'
           EOS

        source_path = cask.staged_path.join("Caffeine Mini.app")

        File.identical?(source_path, Hbc.appdir.join("Caffeine Mini.app")).must_equal false
      end

      it "when the second app of two already exists" do
        Hbc.appdir.join("Caffeine Pro.app").mkpath

        TestHelper.must_output(self, lambda {
          Hbc::Artifact::App.new(cask).install_phase
        }, <<-EOS.undent.chomp)
             ==> Moving App 'Caffeine Mini.app' to '#{Hbc.appdir.join('Caffeine Mini.app')}'
             ==> It seems there is already an App at '#{Hbc.appdir.join('Caffeine Pro.app')}'; not moving.
           EOS

        source_path = cask.staged_path.join("Caffeine Pro.app")

        File.identical?(source_path, Hbc.appdir.join("Caffeine Pro.app")).must_equal false
      end
    end
  end
end
