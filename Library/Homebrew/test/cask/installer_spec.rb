describe Hbc::Installer, :cask do
  describe "install" do
    let(:empty_depends_on_stub) {
      double(formula: [], cask: [], macos: nil, arch: nil, x11: nil)
    }

    it "downloads and installs a nice fresh Cask" do
      caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))

      Hbc::Installer.new(caffeine).install

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).to be_a_directory
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
    end

    it "works with dmg-based Casks" do
      asset = Hbc::CaskLoader.load(cask_path("container-dmg"))

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-dmg", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with tar-gz-based Casks" do
      asset = Hbc::CaskLoader.load(cask_path("container-tar-gz"))

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-tar-gz", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with xar-based Casks" do
      asset = Hbc::CaskLoader.load(cask_path("container-xar"))

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-xar", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with pure bzip2-based Casks" do
      asset = Hbc::CaskLoader.load(cask_path("container-bzip2"))

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-bzip2", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container-bzip2--#{asset.version}")).to be_a_file
    end

    it "works with pure gzip-based Casks" do
      asset = Hbc::CaskLoader.load(cask_path("container-gzip"))

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-gzip", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "blows up on a bad checksum" do
      bad_checksum = Hbc::CaskLoader.load(cask_path("bad-checksum"))
      expect {
        Hbc::Installer.new(bad_checksum).install
      }.to raise_error(Hbc::CaskSha256MismatchError)
    end

    it "blows up on a missing checksum" do
      missing_checksum = Hbc::CaskLoader.load(cask_path("missing-checksum"))
      expect {
        Hbc::Installer.new(missing_checksum).install
      }.to raise_error(Hbc::CaskSha256MissingError)
    end

    it "installs fine if sha256 :no_check is used" do
      no_checksum = Hbc::CaskLoader.load(cask_path("no-checksum"))

      Hbc::Installer.new(no_checksum).install

      expect(no_checksum).to be_installed
    end

    it "fails to install if sha256 :no_check is used with --require-sha" do
      no_checksum = Hbc::CaskLoader.load(cask_path("no-checksum"))
      expect {
        Hbc::Installer.new(no_checksum, require_sha: true).install
      }.to raise_error(Hbc::CaskNoShasumError)
    end

    it "installs fine if sha256 :no_check is used with --require-sha and --force" do
      no_checksum = Hbc::CaskLoader.load(cask_path("no-checksum"))

      Hbc::Installer.new(no_checksum, require_sha: true, force: true).install

      expect(no_checksum).to be_installed
    end

    it "prints caveats if they're present" do
      with_caveats = Hbc::CaskLoader.load(cask_path("with-caveats"))

      expect {
        Hbc::Installer.new(with_caveats).install
      }.to output(/Here are some things you might want to know/).to_stdout

      expect(with_caveats).to be_installed
    end

    it "prints installer :manual instructions when present" do
      with_installer_manual = Hbc::CaskLoader.load(cask_path("with-installer-manual"))

      expect {
        Hbc::Installer.new(with_installer_manual).install
      }.to output(/To complete the installation of Cask with-installer-manual, you must also\nrun the installer at\n\n  '#{with_installer_manual.staged_path.join('Caffeine.app')}'/).to_stdout

      expect(with_installer_manual).to be_installed
    end

    it "does not extract __MACOSX directories from zips" do
      with_macosx_dir = Hbc::CaskLoader.load(cask_path("with-macosx-dir"))

      Hbc::Installer.new(with_macosx_dir).install

      expect(with_macosx_dir.staged_path.join("__MACOSX")).not_to be_a_directory
    end

    it "allows already-installed Casks which auto-update to be installed if force is provided" do
      with_auto_updates = Hbc::CaskLoader.load(cask_path("auto-updates"))

      expect(with_auto_updates).not_to be_installed

      Hbc::Installer.new(with_auto_updates).install

      expect {
        Hbc::Installer.new(with_auto_updates, force: true).install
      }.not_to raise_error
    end

    # unlike the CLI, the internal interface throws exception on double-install
    it "installer method raises an exception when already-installed Casks are attempted" do
      transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))

      expect(transmission).not_to be_installed

      installer = Hbc::Installer.new(transmission)

      installer.install

      expect {
        installer.install
      }.to raise_error(Hbc::CaskAlreadyInstalledError)
    end

    it "allows already-installed Casks to be installed if force is provided" do
      transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))

      expect(transmission).not_to be_installed

      Hbc::Installer.new(transmission).install

      expect {
        Hbc::Installer.new(transmission, force: true).install
      }.not_to raise_error
    end

    it "works naked-pkg-based Casks" do
      naked_pkg = Hbc::CaskLoader.load(cask_path("container-pkg"))

      Hbc::Installer.new(naked_pkg).install

      expect(Hbc.caskroom.join("container-pkg", naked_pkg.version, "container.pkg")).to be_a_file
    end

    it "works properly with an overridden container :type" do
      naked_executable = Hbc::CaskLoader.load(cask_path("naked-executable"))

      Hbc::Installer.new(naked_executable).install

      expect(Hbc.caskroom.join("naked-executable", naked_executable.version, "naked_executable")).to be_a_file
    end

    it "works fine with a nested container" do
      nested_app = Hbc::CaskLoader.load(cask_path("nested-app"))

      Hbc::Installer.new(nested_app).install

      expect(Hbc.appdir.join("MyNestedApp.app")).to be_a_directory
    end

    it "generates and finds a timestamped metadata directory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))

      Hbc::Installer.new(caffeine).install

      m_path = caffeine.metadata_timestamped_path(timestamp: :now, create: true)
      expect(caffeine.metadata_timestamped_path(timestamp: :latest)).to eq(m_path)
    end

    it "generates and finds a metadata subdirectory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))

      Hbc::Installer.new(caffeine).install

      subdir_name = "Casks"
      m_subdir = caffeine.metadata_subdir(subdir_name, timestamp: :now, create: true)
      expect(caffeine.metadata_subdir(subdir_name, timestamp: :latest)).to eq(m_subdir)
    end
  end

  describe "uninstall" do
    it "fully uninstalls a Cask" do
      caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))
      installer = Hbc::Installer.new(caffeine)

      installer.install
      installer.uninstall

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version, "Caffeine.app")).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine")).not_to be_a_directory
    end

    it "uninstalls all versions if force is set" do
      caffeine = Hbc::CaskLoader.load(cask_path("local-caffeine"))
      mutated_version = caffeine.version + ".1"

      Hbc::Installer.new(caffeine).install

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).not_to be_a_directory
      FileUtils.mv(Hbc.caskroom.join("local-caffeine", caffeine.version), Hbc.caskroom.join("local-caffeine", mutated_version))
      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).to be_a_directory

      Hbc::Installer.new(caffeine, force: true).uninstall

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine")).not_to be_a_directory
    end
  end
end
