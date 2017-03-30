describe Hbc::Artifact::Uninstall, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installable.rb") }

  let(:uninstall_artifact) {
    Hbc::Artifact::Uninstall.new(cask, command: Hbc::FakeSystemCommand)
  }

  let(:dir) { TEST_TMPDIR }
  let(:absolute_path) { Pathname.new("#{dir}/absolute_path") }
  let(:path_with_tilde) { Pathname.new("#{dir}/path_with_tilde") }
  let(:glob_path1) { Pathname.new("#{dir}/glob_path1") }
  let(:glob_path2) { Pathname.new("#{dir}/glob_path2") }

  around(:each) do |example|
    begin
      ENV["HOME"] = dir

      paths = [
        absolute_path,
        path_with_tilde,
        glob_path1,
        glob_path2,
      ]

      FileUtils.touch paths

      shutup do
        InstallHelper.install_without_artifacts(cask)
      end

      example.run
    ensure
      FileUtils.rm_f paths
    end
  end

  describe "uninstall_phase" do
    subject {
      shutup do
        uninstall_artifact.uninstall_phase
      end
    }

    context "when using launchctl" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-launchctl.rb") }
      let(:launchctl_list_cmd) { %w[/bin/launchctl list my.fancy.package.service] }
      let(:launchctl_remove_cmd) { %w[/bin/launchctl remove my.fancy.package.service] }
      let(:unknown_response) { "launchctl list returned unknown response\n" }
      let(:service_info) {
        <<-EOS.undent
          {
                  "LimitLoadToSessionType" = "Aqua";
                  "Label" = "my.fancy.package.service";
                  "TimeOut" = 30;
                  "OnDemand" = true;
                  "LastExitStatus" = 0;
                  "ProgramArguments" = (
                          "argument";
                  );
          };
        EOS
      }

      context "when launchctl job is owned by user" do
        it "can uninstall" do
          Hbc::FakeSystemCommand.stubs_command(
            launchctl_list_cmd,
            service_info,
          )

          Hbc::FakeSystemCommand.stubs_command(
            sudo(launchctl_list_cmd),
            unknown_response,
          )

          Hbc::FakeSystemCommand.expects_command(launchctl_remove_cmd)

          subject
        end
      end

      context "when launchctl job is owned by system" do
        it "can uninstall" do
          Hbc::FakeSystemCommand.stubs_command(
            launchctl_list_cmd,
            unknown_response,
          )

          Hbc::FakeSystemCommand.stubs_command(
            sudo(launchctl_list_cmd),
            service_info,
          )

          Hbc::FakeSystemCommand.expects_command(sudo(launchctl_remove_cmd))

          subject
        end
      end
    end

    context "when using pkgutil" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-pkgutil.rb") }
      let(:main_pkg_id) { "my.fancy.package.main" }
      let(:agent_pkg_id) { "my.fancy.package.agent" }
      let(:main_files) {
        %w[
          fancy/bin/fancy.exe
          fancy/var/fancy.data
        ]
      }
      let(:main_dirs) {
        %w[
          fancy
          fancy/bin
          fancy/var
        ]
      }
      let(:agent_files) {
        %w[
          fancy/agent/fancy-agent.exe
          fancy/agent/fancy-agent.pid
          fancy/agent/fancy-agent.log
        ]
      }
      let(:agent_dirs) {
        %w[
          fancy
          fancy/agent
        ]
      }
      let(:pkg_info_plist) {
        <<-EOS.undent
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
                  <key>install-location</key>
                  <string>tmp</string>
                  <key>volume</key>
                  <string>/</string>
          </dict>
          </plist>
        EOS
      }

      it "can uninstall" do
        Hbc::FakeSystemCommand.stubs_command(
          %w[/usr/sbin/pkgutil --pkgs=my.fancy.package.*],
          "#{main_pkg_id}\n#{agent_pkg_id}",
        )

        [
          [main_pkg_id, main_files, main_dirs],
          [agent_pkg_id, agent_files, agent_dirs],
        ].each do |pkg_id, pkg_files, pkg_dirs|
          Hbc::FakeSystemCommand.stubs_command(
            %W[/usr/sbin/pkgutil --only-files --files #{pkg_id}],
            pkg_files.join("\n"),
          )

          Hbc::FakeSystemCommand.stubs_command(
            %W[/usr/sbin/pkgutil --only-dirs --files #{pkg_id}],
            pkg_dirs.join("\n"),
          )

          Hbc::FakeSystemCommand.stubs_command(
            %W[/usr/sbin/pkgutil --files #{pkg_id}],
            (pkg_files + pkg_dirs).join("\n"),
          )

          Hbc::FakeSystemCommand.stubs_command(
            %W[/usr/sbin/pkgutil --pkg-info-plist #{pkg_id}],
            pkg_info_plist,
          )

          Hbc::FakeSystemCommand.expects_command(sudo(%W[/usr/sbin/pkgutil --forget #{pkg_id}]))

          Hbc::FakeSystemCommand.expects_command(
            sudo(%w[/bin/rm -f --] + pkg_files.map { |path| Pathname("/tmp/#{path}") }),
          )
        end

        subject
      end
    end

    context "when using kext" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-kext.rb") }
      let(:kext_id) { "my.fancy.package.kernelextension" }

      it "can uninstall" do
        Hbc::FakeSystemCommand.stubs_command(
          sudo(%W[/usr/sbin/kextstat -l -b #{kext_id}]), "loaded"
        )

        Hbc::FakeSystemCommand.expects_command(
          sudo(%W[/sbin/kextunload -b #{kext_id}]),
        )

        Hbc::FakeSystemCommand.expects_command(
          sudo(%W[/usr/sbin/kextfind -b #{kext_id}]), "/Library/Extensions/FancyPackage.kext\n"
        )

        Hbc::FakeSystemCommand.expects_command(
          sudo(["/bin/rm", "-rf", "/Library/Extensions/FancyPackage.kext"]),
        )

        subject
      end
    end

    context "when using quit" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-quit.rb") }
      let(:bundle_id) { "my.fancy.package.app" }
      let(:quit_application_script) {
        %Q(tell application id "#{bundle_id}" to quit)
      }

      it "can uninstall" do
        Hbc::FakeSystemCommand.stubs_command(
          %w[/bin/launchctl list], "999\t0\t#{bundle_id}\n"
        )

        Hbc::FakeSystemCommand.stubs_command(
          %w[/bin/launchctl list],
        )

        subject
      end
    end

    context "when using signal" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-signal.rb") }
      let(:bundle_id) { "my.fancy.package.app" }
      let(:signals) { %w[TERM KILL] }
      let(:unix_pids) { [12_345, 67_890] }

      it "can uninstall" do
        Hbc::FakeSystemCommand.stubs_command(
          %w[/bin/launchctl list], unix_pids.map { |pid| [pid, 0, bundle_id].join("\t") }.join("\n")
        )

        signals.each do |signal|
          expect(Process).to receive(:kill).with(signal, *unix_pids)
        end

        subject
      end
    end

    context "when using delete" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-delete.rb") }

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(
          sudo(%w[/bin/rm -rf --],
               absolute_path,
               path_with_tilde,
               glob_path1,
               glob_path2),
        )

        subject
      end
    end

    context "when using trash" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-trash.rb") }

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(
          sudo(%w[/bin/rm -rf --],
               absolute_path,
               path_with_tilde,
               glob_path1,
               glob_path2),
        )

        subject
      end
    end

    context "when using rmdir" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-rmdir.rb") }
      let(:empty_directory_path) { Pathname.new("#{TEST_TMPDIR}/empty_directory_path") }

      before(:each) do
        empty_directory_path.mkdir
      end

      after(:each) do
        empty_directory_path.rmdir
      end

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(
          sudo(%w[/bin/rm -f --], empty_directory_path/".DS_Store"),
        )

        Hbc::FakeSystemCommand.expects_command(
          sudo(%w[/bin/rmdir --], empty_directory_path),
        )

        subject
      end
    end

    context "when using script" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-script.rb") }
      let(:script_pathname) { cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool") }

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(%w[/bin/chmod -- +x] + [script_pathname])

        Hbc::FakeSystemCommand.expects_command(
          sudo(cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool"), "--please"),
        )

        subject
      end
    end

    context "when using early_script" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-early-script.rb") }
      let(:script_pathname) { cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool") }

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(%w[/bin/chmod -- +x] + [script_pathname])

        Hbc::FakeSystemCommand.expects_command(
          sudo(cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool"), "--please"),
        )

        subject
      end
    end

    context "when using login_item" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-uninstall-login-item.rb") }

      it "can uninstall" do
        Hbc::FakeSystemCommand.expects_command(
          ["/usr/bin/osascript", "-e", 'tell application "System Events" to delete every login ' \
                                       'item whose name is "Fancy"'],
        )

        subject
      end
    end
  end
end
