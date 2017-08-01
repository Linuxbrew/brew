describe Hbc::Artifact::App, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb") }
  let(:command) { Hbc::SystemCommand }
  let(:force) { false }
  let(:app) { Hbc::Artifact::App.new(cask, command: command, force: force) }

  let(:source_path) { cask.staged_path.join("Caffeine.app") }
  let(:target_path) { Hbc.appdir.join("Caffeine.app") }

  let(:install_phase) { app.install_phase }
  let(:uninstall_phase) { app.uninstall_phase }

  before(:each) do
    InstallHelper.install_without_artifacts(cask)
  end

  describe "install_phase" do
    it "installs the given app using the proper target directory" do
      install_phase

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
          app "subdir/Caffeine.app"
        end
      }

      it "installs the given app using the proper target directory" do
        appsubdir = cask.staged_path.join("subdir").tap(&:mkpath)
        FileUtils.mv(source_path, appsubdir)

        install_phase

        expect(target_path).to be_a_directory
        expect(appsubdir.join("Caffeine.app")).not_to exist
      end
    end

    it "only uses apps when they are specified" do
      staged_app_copy = source_path.sub("Caffeine.app", "Caffeine Deluxe.app")
      FileUtils.cp_r source_path, staged_app_copy

      install_phase

      expect(target_path).to be_a_directory
      expect(source_path).not_to exist

      expect(Hbc.appdir.join("Caffeine Deluxe.app")).not_to exist
      expect(cask.staged_path.join("Caffeine Deluxe.app")).to exist
    end

    describe "when the target already exists" do
      before(:each) do
        target_path.mkpath
      end

      it "avoids clobbering an existing app" do
        expect { install_phase }.to raise_error(Hbc::CaskError, "It seems there is already an App at '#{target_path}'.")

        expect(source_path).to be_a_directory
        expect(target_path).to be_a_directory
        expect(File.identical?(source_path, target_path)).to be false

        contents_path = target_path.join("Contents/Info.plist")
        expect(contents_path).not_to exist
      end

      describe "given the force option" do
        let(:force) { true }

        before(:each) do
          allow(Hbc::Utils).to receive(:current_user).and_return("fake_user")
        end

        describe "target is both writable and user-owned" do
          it "overwrites the existing app" do
            stdout = <<-EOS.undent
              ==> Removing App '#{target_path}'.
              ==> Moving App 'Caffeine.app' to '#{target_path}'.
            EOS

            stderr = <<-EOS.undent
              Warning: It seems there is already an App at '#{target_path}'; overwriting.
            EOS

            expect { install_phase }
              .to output(stdout).to_stdout
              .and output(stderr).to_stderr

            expect(source_path).not_to exist
            expect(target_path).to be_a_directory

            contents_path = target_path.join("Contents/Info.plist")
            expect(contents_path).to exist
          end
        end

        describe "target is user-owned but contains read-only files" do
          before(:each) do
            system "/usr/bin/touch", "--", "#{target_path}/foo"
            system "/bin/chmod", "--", "0555", target_path
          end

          it "overwrites the existing app" do
            expect(command).to receive(:run).with("/bin/chmod", args: ["-R", "--", "u+rwx", target_path], must_succeed: false)
              .and_call_original
            expect(command).to receive(:run).with("/bin/chmod", args: ["-R", "-N", target_path], must_succeed: false)
              .and_call_original
            expect(command).to receive(:run).with("/usr/bin/chflags", args: ["-R", "--", "000", target_path], must_succeed: false)
              .and_call_original

            stdout = <<-EOS.undent
              ==> Removing App '#{target_path}'.
              ==> Moving App 'Caffeine.app' to '#{target_path}'.
            EOS

            stderr = <<-EOS.undent
              Warning: It seems there is already an App at '#{target_path}'; overwriting.
            EOS

            expect { install_phase }
              .to output(stdout).to_stdout
              .and output(stderr).to_stderr

            expect(source_path).not_to exist
            expect(target_path).to be_a_directory

            contents_path = target_path.join("Contents/Info.plist")
            expect(contents_path).to exist
          end

          after(:each) do
            system "/bin/chmod", "--", "0755", target_path
          end
        end
      end
    end

    describe "when the target is a broken symlink" do
      let(:deleted_path) { cask.staged_path.join("Deleted.app") }

      before(:each) do
        deleted_path.mkdir
        File.symlink(deleted_path, target_path)
        deleted_path.rmdir
      end

      it "leaves the target alone" do
        expect { install_phase }.to raise_error(Hbc::CaskError, "It seems there is already an App at '#{target_path}'.")
        expect(target_path).to be_a_symlink
      end

      describe "given the force option" do
        let(:force) { true }

        it "overwrites the existing app" do
          stdout = <<-EOS.undent
            ==> Removing App '#{target_path}'.
            ==> Moving App 'Caffeine.app' to '#{target_path}'.
          EOS

          stderr = <<-EOS.undent
            Warning: It seems there is already an App at '#{target_path}'; overwriting.
          EOS

          expect { install_phase }
            .to output(stdout).to_stdout
            .and output(stderr).to_stderr

          expect(source_path).not_to exist
          expect(target_path).to be_a_directory

          contents_path = target_path.join("Contents/Info.plist")
          expect(contents_path).to exist
        end
      end
    end

    it "gives a warning if the source doesn't exist" do
      source_path.rmtree

      message = "It seems the App source '#{source_path}' is not there."

      expect { install_phase }.to raise_error(Hbc::CaskError, message)
    end
  end

  describe "uninstall_phase" do
    it "deletes managed apps" do
      install_phase

      expect(target_path).to exist

      uninstall_phase

      expect(target_path).not_to exist
    end
  end

  describe "summary" do
    let(:description) { app.summary[:english_description] }
    let(:contents) { app.summary[:contents] }

    it "returns the correct english_description" do
      expect(description).to eq("Apps")
    end

    describe "app is correctly installed" do
      it "returns the path to the app" do
        install_phase

        expect(contents).to eq(["#{target_path} (#{target_path.abv})"])
      end
    end

    describe "app is missing" do
      it "returns a warning and the supposed path to the app" do
        expect(contents.size).to eq(1)
        expect(contents[0]).to match(/.*Missing App.*: #{target_path}/)
      end
    end
  end
end
