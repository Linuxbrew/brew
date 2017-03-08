shared_examples "#uninstall_phase or #zap_phase" do
  let(:artifact_name) { described_class.artifact_name }
  let(:artifact) { described_class.new(cask, command: fake_system_command) }
  let(:fake_system_command) { Hbc::FakeSystemCommand }

  subject do
    shutup do
      artifact.public_send(:"#{artifact_name}_phase")
    end
  end

  context "using :launchctl" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-launchctl.rb") }
    let(:launchctl_list_cmd) { %w[/bin/launchctl list my.fancy.package.service] }
    let(:launchctl_remove_cmd) { %w[/bin/launchctl remove my.fancy.package.service] }
    let(:unknown_response) { "launchctl list returned unknown response\n" }
    let(:service_info) do
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
    end

    it "works when job is owned by user" do
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

    it "works when job is owned by system" do
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

  context "using :pkgutil" do
    let(:fake_system_command) { class_double(Hbc::SystemCommand) }

    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-pkgutil.rb") }
    let(:main_pkg_id) { "my.fancy.package.main" }
    let(:agent_pkg_id) { "my.fancy.package.agent" }
    let(:main_files) do
      %w[
        fancy/bin/fancy.exe
        fancy/var/fancy.data
      ]
    end
    let(:main_dirs) do
      %w[
        fancy
        fancy/bin
        fancy/var
      ]
    end
    let(:agent_files) do
      %w[
        fancy/agent/fancy-agent.exe
        fancy/agent/fancy-agent.pid
        fancy/agent/fancy-agent.log
      ]
    end
    let(:agent_dirs) do
      %w[
        fancy
        fancy/agent
      ]
    end
    let(:pkg_info_plist) do
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
    end

    it "is supported" do
      allow(fake_system_command).to receive(:run).with(
        "/usr/sbin/pkgutil",
        args: ["--pkgs=my.fancy.package.*"],
      ).and_return(double(stdout: "#{main_pkg_id}\n#{agent_pkg_id}"))

      [
        [main_pkg_id, main_files, main_dirs],
        [agent_pkg_id, agent_files, agent_dirs],
      ].each do |pkg_id, pkg_files, pkg_dirs|

        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--only-files", "--files", pkg_id.to_s],
        ).and_return(double(stdout: pkg_files.join("\n")))

        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--only-dirs", "--files", pkg_id.to_s],
        ).and_return(double(stdout: pkg_dirs.join("\n")))

        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--files", pkg_id.to_s],
        ).and_return(double(stdout: (pkg_files + pkg_dirs).join("\n")))

        result = Hbc::SystemCommand::Result.new(nil, pkg_info_plist, nil, 0)
        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--pkg-info-plist", pkg_id.to_s],
        ).and_return(result)

        expect(fake_system_command).to receive(:run).with(
          "/usr/bin/xargs",
          args: ["-0", "--", "/bin/rm", "-f", "--"],
          input: pkg_files.map { |path| "/tmp/#{path}" }.join("\0"),
          sudo: true,
        )

        expect(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--forget", pkg_id.to_s],
          sudo: true,
        )
      end

      subject
    end
  end

  context "using :kext" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-kext.rb") }
    let(:kext_id) { "my.fancy.package.kernelextension" }

    it "is supported" do
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

  context "using :quit" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-quit.rb") }
    let(:bundle_id) { "my.fancy.package.app" }
    let(:quit_application_script) do
      %Q(tell application id "#{bundle_id}" to quit)
    end

    it "is supported" do
      Hbc::FakeSystemCommand.stubs_command(
        %w[/bin/launchctl list], "999\t0\t#{bundle_id}\n"
      )

      Hbc::FakeSystemCommand.stubs_command(
        %w[/bin/launchctl list],
      )

      subject
    end
  end

  context "using :signal" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-signal.rb") }
    let(:bundle_id) { "my.fancy.package.app" }
    let(:signals) { %w[TERM KILL] }
    let(:unix_pids) { [12_345, 67_890] }

    it "is supported" do
      Hbc::FakeSystemCommand.stubs_command(
        %w[/bin/launchctl list], unix_pids.map { |pid| [pid, 0, bundle_id].join("\t") }.join("\n")
      )

      signals.each do |signal|
        expect(Process).to receive(:kill).with(signal, *unix_pids)
      end

      subject
    end
  end

  [:delete, :trash].each do |directive|
    context "using :#{directive}" do
      let(:dir) { TEST_TMPDIR }
      let(:absolute_path) { Pathname.new("#{dir}/absolute_path") }
      let(:path_with_tilde) { Pathname.new("#{dir}/path_with_tilde") }
      let(:glob_path1) { Pathname.new("#{dir}/glob_path1") }
      let(:glob_path2) { Pathname.new("#{dir}/glob_path2") }
      let(:paths) { [absolute_path, path_with_tilde, glob_path1, glob_path2] }

      around(:each) do |example|
        begin
          ENV["HOME"] = dir

          FileUtils.touch paths

          example.run
        ensure
          FileUtils.rm_f paths
        end
      end

      let(:fake_system_command) { Hbc::NeverSudoSystemCommand }
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-#{directive}.rb") }

      it "is supported" do
        paths.each do |path|
          expect(path).to exist
        end

        subject

        paths.each do |path|
          expect(path).not_to exist
        end
      end
    end
  end

  context "using :rmdir" do
    let(:fake_system_command) { Hbc::NeverSudoSystemCommand }
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-rmdir.rb") }
    let(:empty_directory) { Pathname.new("#{TEST_TMPDIR}/empty_directory_path") }
    let(:ds_store) { empty_directory.join(".DS_Store") }

    before(:each) do
      empty_directory.mkdir
      FileUtils.touch ds_store
    end

    after(:each) do
      FileUtils.rm_rf empty_directory
    end

    it "is supported" do
      expect(empty_directory).to exist
      expect(ds_store).to exist

      subject

      expect(ds_store).not_to exist
      expect(empty_directory).not_to exist
    end
  end

  context "using :script" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-script.rb") }
    let(:script_pathname) { cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool") }

    it "is supported" do
      Hbc::FakeSystemCommand.expects_command(%w[/bin/chmod -- +x] + [script_pathname])

      Hbc::FakeSystemCommand.expects_command(
        sudo(cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool"), "--please"),
      )

      InstallHelper.install_without_artifacts(cask)
      subject
    end
  end

  context "using :early_script" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-early-script.rb") }
    let(:script_pathname) { cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool") }

    it "is supported" do
      Hbc::FakeSystemCommand.expects_command(%w[/bin/chmod -- +x] + [script_pathname])

      Hbc::FakeSystemCommand.expects_command(
        sudo(cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool"), "--please"),
      )

      InstallHelper.install_without_artifacts(cask)
      subject
    end
  end

  context "using :login_item" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-#{artifact_name}-login-item.rb") }

    it "is supported" do
      Hbc::FakeSystemCommand.expects_command(
        ["/usr/bin/osascript", "-e", 'tell application "System Events" to delete every login ' \
                                     'item whose name is "Fancy"'],
      )

      subject
    end
  end
end
