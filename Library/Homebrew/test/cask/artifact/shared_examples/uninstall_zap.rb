require "benchmark"

shared_examples "#uninstall_phase or #zap_phase" do
  subject { artifact }

  let(:artifact_dsl_key) { described_class.dsl_key }
  let(:artifact) { cask.artifacts.find { |a| a.is_a?(described_class) } }
  let(:fake_system_command) { FakeSystemCommand }

  context "using :launchctl" do
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-launchctl")) }
    let(:launchctl_list_cmd) { %w[/bin/launchctl list my.fancy.package.service] }
    let(:launchctl_remove_cmd) { %w[/bin/launchctl remove my.fancy.package.service] }
    let(:unknown_response) { "launchctl list returned unknown response\n" }
    let(:service_info) do
      <<~EOS
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
      FakeSystemCommand.stubs_command(
        launchctl_list_cmd,
        service_info,
      )

      FakeSystemCommand.stubs_command(
        sudo(launchctl_list_cmd),
        unknown_response,
      )

      FakeSystemCommand.expects_command(launchctl_remove_cmd)

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end

    it "works when job is owned by system" do
      FakeSystemCommand.stubs_command(
        launchctl_list_cmd,
        unknown_response,
      )

      FakeSystemCommand.stubs_command(
        sudo(launchctl_list_cmd),
        service_info,
      )

      FakeSystemCommand.expects_command(sudo(launchctl_remove_cmd))

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end
  end

  context "using :pkgutil" do
    let(:fake_system_command) { class_double(SystemCommand) }

    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-pkgutil")) }

    let(:main_pkg_id) { "my.fancy.package.main" }
    let(:agent_pkg_id) { "my.fancy.package.agent" }

    it "is supported" do
      main_pkg = Cask::Pkg.new(main_pkg_id, fake_system_command)
      agent_pkg = Cask::Pkg.new(agent_pkg_id, fake_system_command)

      expect(Cask::Pkg).to receive(:all_matching).and_return(
        [
          main_pkg,
          agent_pkg,
        ],
      )

      expect(main_pkg).to receive(:uninstall)
      expect(agent_pkg).to receive(:uninstall)

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end
  end

  context "using :kext" do
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-kext")) }
    let(:kext_id) { "my.fancy.package.kernelextension" }

    it "is supported" do
      allow(subject).to receive(:system_command!)
        .with("/usr/sbin/kextstat", args: ["-l", "-b", kext_id], sudo: true)
        .and_return(instance_double("SystemCommand::Result", stdout: "loaded"))

      expect(subject).to receive(:system_command!)
        .with("/sbin/kextunload", args: ["-b", kext_id], sudo: true)
        .and_return(instance_double("SystemCommand::Result"))

      expect(subject).to receive(:system_command!)
        .with("/usr/sbin/kextfind", args: ["-b", kext_id], sudo: true)
        .and_return(instance_double("SystemCommand::Result", stdout: "/Library/Extensions/FancyPackage.kext\n"))

      expect(subject).to receive(:system_command!)
        .with("/bin/rm", args: ["-rf", "/Library/Extensions/FancyPackage.kext"], sudo: true)

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end
  end

  context "using :quit" do
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-quit")) }
    let(:bundle_id) { "my.fancy.package.app" }

    it "is skipped when the user is not a GUI user" do
      allow(User.current).to receive(:gui?).and_return false
      allow(subject).to receive(:running_processes).with(bundle_id).and_return([[0, "", bundle_id]])

      expect {
        subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
      }.to output(/Not logged into a GUI; skipping quitting application ID 'my.fancy.package.app'\./).to_stdout
    end

    it "quits a running application" do
      allow(User.current).to receive(:gui?).and_return true

      expect(subject).to receive(:running_processes).with(bundle_id).ordered.and_return([[0, "", bundle_id]])
      expect(subject).to receive(:quit).with(bundle_id)
                                       .and_return(instance_double("SystemCommand::Result", success?: true))
      expect(subject).to receive(:running_processes).with(bundle_id).ordered.and_return([])

      expect {
        subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
      }.to output(/Application 'my.fancy.package.app' quit successfully\./).to_stdout
    end

    it "tries to quit the application for 10 seconds" do
      allow(User.current).to receive(:gui?).and_return true

      allow(subject).to receive(:running_processes).with(bundle_id).and_return([[0, "", bundle_id]])
      allow(subject).to receive(:quit).with(bundle_id)
                                      .and_return(instance_double("SystemCommand::Result", success?: false))

      time = Benchmark.measure do
        expect {
          subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
        }.to output(/Application 'my.fancy.package.app' did not quit\./).to_stderr
      end

      expect(time.real).to be_within(3).of(10)
    end
  end

  context "using :signal" do
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-signal")) }
    let(:bundle_id) { "my.fancy.package.app" }
    let(:signals) { %w[TERM KILL] }
    let(:unix_pids) { [12_345, 67_890] }

    it "is supported" do
      allow(subject).to receive(:running_processes).with(bundle_id)
                                                   .and_return(unix_pids.map { |pid| [pid, 0, bundle_id] })

      signals.each do |signal|
        expect(Process).to receive(:kill).with(signal, *unix_pids)
      end

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end
  end

  [:delete, :trash].each do |directive|
    next if directive == :trash && ENV["HOMEBREW_TESTS_COVERAGE"].nil?

    context "using :#{directive}" do
      let(:dir) { TEST_TMPDIR }
      let(:absolute_path) { Pathname.new("#{dir}/absolute_path") }
      let(:path_with_tilde) { Pathname.new("#{dir}/path_with_tilde") }
      let(:glob_path1) { Pathname.new("#{dir}/glob_path1") }
      let(:glob_path2) { Pathname.new("#{dir}/glob_path2") }
      let(:paths) { [absolute_path, path_with_tilde, glob_path1, glob_path2] }
      let(:fake_system_command) { NeverSudoSystemCommand }
      let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-#{directive}")) }

      around do |example|
        begin
          ENV["HOME"] = dir

          FileUtils.touch paths

          example.run
        ensure
          FileUtils.rm_f paths
        end
      end

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Cask::Artifact::AbstractUninstall).to receive(:trash_paths)
          .and_wrap_original do |method, *args|
            method.call(*args).tap do |result|
              FileUtils.rm_rf result.stdout.split("\0")
            end
          end
        # rubocop:enable RSpec/AnyInstance
      end

      it "is supported" do
        expect(paths).to all(exist)

        subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)

        paths.each do |path|
          expect(path).not_to exist
        end
      end
    end
  end

  context "using :rmdir" do
    let(:fake_system_command) { NeverSudoSystemCommand }
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-rmdir")) }
    let(:empty_directory) { Pathname.new("#{TEST_TMPDIR}/empty_directory_path") }
    let(:ds_store) { empty_directory.join(".DS_Store") }

    before do
      empty_directory.mkdir
      FileUtils.touch ds_store
    end

    after do
      FileUtils.rm_rf empty_directory
    end

    it "is supported" do
      expect(empty_directory).to exist
      expect(ds_store).to exist

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)

      expect(ds_store).not_to exist
      expect(empty_directory).not_to exist
    end
  end

  [:script, :early_script].each do |script_type|
    context "using #{script_type.inspect}" do
      let(:fake_system_command) { NeverSudoSystemCommand }
      let(:token) { "with-#{artifact_dsl_key}-#{script_type}".tr("_", "-") }
      let(:cask) { Cask::CaskLoader.load(cask_path(token.to_s)) }
      let(:script_pathname) { cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool") }

      it "is supported" do
        allow(fake_system_command).to receive(:run).with(any_args).and_call_original

        expect(fake_system_command).to receive(:run).with(
          "/bin/chmod",
          args: ["--", "+x", script_pathname],
        )

        expect(fake_system_command).to receive(:run).with(
          cask.staged_path.join("MyFancyPkg", "FancyUninstaller.tool"),
          args:         ["--please"],
          must_succeed: true,
          print_stdout: true,
          sudo:         false,
        )

        InstallHelper.install_without_artifacts(cask)
        subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
      end
    end
  end

  context "using :login_item" do
    let(:cask) { Cask::CaskLoader.load(cask_path("with-#{artifact_dsl_key}-login-item")) }

    it "is supported" do
      expect(subject).to receive(:system_command!)
        .with(
          "osascript",
        args: ["-e", 'tell application "System Events" to delete every login item whose name is "Fancy"'],
      )
        .and_return(instance_double("SystemCommand::Result"))

      subject.public_send(:"#{artifact_dsl_key}_phase", command: fake_system_command)
    end
  end
end
