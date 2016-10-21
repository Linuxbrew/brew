require "test_helper"

describe Hbc::Artifact::App do
  let(:cask) { Hbc.load("local-caffeine") }
  let(:command) { Hbc::SystemCommand }
  let(:force) { false }
  let(:app) { Hbc::Artifact::App.new(cask, command: command, force: force) }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  let(:install_phase) { -> { app.install_phase } }
  let(:uninstall_phase) { -> { app.uninstall_phase } }

  before do
    TestHelper.install_without_artifacts(cask)
  end

  describe "install_phase" do
    it "installs the given app using the proper target directory" do
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
          app "subdir/Caffeine.app"
        end
      }

      it "installs the given app using the proper target directory" do
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
      cask.staged_path.join("Caffeine Deluxe.app").must_be :exist?
    end

    describe "when the target already exists" do
      before do
        target_path.mkpath
      end

      it "avoids clobbering an existing app" do
        install_phase.must_output <<-EOS.undent
          ==> It seems there is already an App at '#{target_path}'; not moving.
        EOS

        source_path.must_be :directory?
        target_path.must_be :directory?
        File.identical?(source_path, target_path).must_equal false

        contents_path = target_path.join("Contents/Info.plist")
        contents_path.wont_be :exist?
      end

      describe "given the force option" do
        let(:force) { true }

        before do
          Hbc::Utils.stubs(current_user: "fake_user")
        end

        describe "target is both writable and user-owned" do
          it "overwrites the existing app" do
            install_phase.must_output <<-EOS.undent
              ==> It seems there is already an App at '#{target_path}'; overwriting.
              ==> Removing App: '#{target_path}'
              ==> Moving App 'Caffeine.app' to '#{target_path}'
            EOS

            source_path.wont_be :exist?
            target_path.must_be :directory?

            contents_path = target_path.join("Contents/Info.plist")
            contents_path.must_be :exist?
          end
        end

        describe "target is user-owned but contains read-only files" do
          let(:command) { Hbc::FakeSystemCommand }

          let(:chmod_cmd) {
            ["/bin/chmod", "-R", "--", "u+rwx", target_path]
          }

          let(:chmod_n_cmd) {
            ["/bin/chmod", "-R", "-N", target_path]
          }

          let(:chflags_cmd) {
            ["/usr/bin/chflags", "-R", "--", "000", target_path]
          }

          before do
            system "/usr/bin/touch", "--", "#{target_path}/foo"
            system "/bin/chmod", "--", "0555", target_path
          end

          it "overwrites the existing app" do
            command.expect_and_pass_through(chflags_cmd)
            command.expect_and_pass_through(chmod_cmd)
            command.expect_and_pass_through(chmod_n_cmd)

            install_phase.must_output <<-EOS.undent
              ==> It seems there is already an App at '#{target_path}'; overwriting.
              ==> Removing App: '#{target_path}'
              ==> Moving App 'Caffeine.app' to '#{target_path}'
            EOS

            source_path.wont_be :exist?
            target_path.must_be :directory?

            contents_path = target_path.join("Contents/Info.plist")
            contents_path.must_be :exist?
          end

          after do
            system "/bin/chmod", "--", "0755", target_path
          end
        end
      end
    end

    describe "when the target is a broken symlink" do
      let(:deleted_path) { cask.staged_path.join("Deleted.app") }

      before do
        deleted_path.mkdir
        File.symlink(deleted_path, target_path)
        deleted_path.rmdir
      end

      it "leaves the target alone" do
        install_phase.must_output <<-EOS.undent
          ==> It seems there is already an App at '#{target_path}'; not moving.
        EOS

        File.symlink?(target_path).must_equal true
      end

      describe "given the force option" do
        let(:force) { true }

        it "overwrites the existing app" do
          install_phase.must_output <<-EOS.undent
            ==> It seems there is already an App at '#{target_path}'; overwriting.
            ==> Removing App: '#{target_path}'
            ==> Moving App 'Caffeine.app' to '#{target_path}'
          EOS

          source_path.wont_be :exist?
          target_path.must_be :directory?

          contents_path = target_path.join("Contents/Info.plist")
          contents_path.must_be :exist?
        end
      end
    end

    it "gives a warning if the source doesn't exist" do
      source_path.rmtree

      message = "It seems the App source is not there: '#{source_path}'"

      error = install_phase.must_raise(Hbc::CaskError)
      error.message.must_equal message
    end
  end

  describe "uninstall_phase" do
    before do
      shutup do
        install_phase.call
      end
    end

    it "deletes managed apps" do
      target_path.must_be :exist?

      shutup do
        uninstall_phase.call
      end

      target_path.wont_be :exist?
    end
  end

  describe "summary" do
    let(:description) { app.summary[:english_description] }
    let(:contents) { app.summary[:contents] }

    it "returns the correct english_description" do
      description.must_equal "Apps"
    end

    describe "app is correctly installed" do
      before do
        shutup do
          install_phase.call
        end
      end

      it "returns the path to the app" do
        contents.must_equal ["#{target_path} (#{target_path.abv})"]
      end
    end

    describe "app is missing" do
      it "returns a warning and the supposed path to the app" do
        contents.size.must_equal 1
        contents[0].must_match(/.*Missing App.*: #{target_path}/)
      end
    end
  end
end
