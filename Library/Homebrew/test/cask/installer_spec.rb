describe Hbc::Installer, :cask do
  describe "install" do
    let(:empty_depends_on_stub) {
      double(formula: [], cask: [], macos: nil, arch: nil, x11: nil)
    }

    it "downloads and installs a nice fresh Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      Hbc::Installer.new(caffeine).install

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).to be_a_directory
      expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
    end

    it "works with dmg-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-dmg.rb")

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-dmg", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with tar-gz-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-tar-gz.rb")

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-tar-gz", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with xar-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-xar.rb")

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-xar", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "works with pure bzip2-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-bzip2.rb")

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-bzip2", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container-bzip2--#{asset.version}")).to be_a_file
    end

    it "works with pure gzip-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-gzip.rb")

      Hbc::Installer.new(asset).install

      expect(Hbc.caskroom.join("container-gzip", asset.version)).to be_a_directory
      expect(Hbc.appdir.join("container")).to be_a_file
    end

    it "blows up on a bad checksum" do
      bad_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/bad-checksum.rb")
      expect {
        Hbc::Installer.new(bad_checksum).install
      }.to raise_error(Hbc::CaskSha256MismatchError)
    end

    it "blows up on a missing checksum" do
      missing_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/missing-checksum.rb")
      expect {
        Hbc::Installer.new(missing_checksum).install
      }.to raise_error(Hbc::CaskSha256MissingError)
    end

    it "installs fine if sha256 :no_check is used" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")

      Hbc::Installer.new(no_checksum).install

      expect(no_checksum).to be_installed
    end

    it "fails to install if sha256 :no_check is used with --require-sha" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")
      expect {
        Hbc::Installer.new(no_checksum, require_sha: true).install
      }.to raise_error(Hbc::CaskNoShasumError)
    end

    it "installs fine if sha256 :no_check is used with --require-sha and --force" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")

      Hbc::Installer.new(no_checksum, require_sha: true, force: true).install

      expect(no_checksum).to be_installed
    end

    it "prints caveats if they're present" do
      with_caveats = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-caveats.rb")

      expect {
        Hbc::Installer.new(with_caveats).install
      }.to output(/Here are some things you might want to know/).to_stdout

      expect(with_caveats).to be_installed
    end

    it "prints installer :manual instructions when present" do
      with_installer_manual = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installer-manual.rb")

      expect {
        Hbc::Installer.new(with_installer_manual).install
      }.to output(/To complete the installation of Cask with-installer-manual, you must also\nrun the installer at\n\n  '#{with_installer_manual.staged_path.join('Caffeine.app')}'/).to_stdout

      expect(with_installer_manual).to be_installed
    end

    it "does not extract __MACOSX directories from zips" do
      with_macosx_dir = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-macosx-dir.rb")

      Hbc::Installer.new(with_macosx_dir).install

      expect(with_macosx_dir.staged_path.join("__MACOSX")).not_to be_a_directory
    end

    it "allows already-installed Casks which auto-update to be installed if force is provided" do
      with_auto_updates = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/auto-updates.rb")

      expect(with_auto_updates).not_to be_installed

      Hbc::Installer.new(with_auto_updates).install

      expect {
        Hbc::Installer.new(with_auto_updates, force: true).install
      }.not_to raise_error
    end

    # unlike the CLI, the internal interface throws exception on double-install
    it "installer method raises an exception when already-installed Casks are attempted" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      expect(transmission).not_to be_installed

      installer = Hbc::Installer.new(transmission)

      installer.install

      expect {
        installer.install
      }.to raise_error(Hbc::CaskAlreadyInstalledError)
    end

    it "allows already-installed Casks to be installed if force is provided" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      expect(transmission).not_to be_installed

      Hbc::Installer.new(transmission).install

      expect {
        Hbc::Installer.new(transmission, force: true).install
      }.not_to raise_error
    end

    it "works naked-pkg-based Casks" do
      naked_pkg = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-pkg.rb")

      Hbc::Installer.new(naked_pkg).install

      expect(Hbc.caskroom.join("container-pkg", naked_pkg.version, "container.pkg")).to be_a_file
    end

    it "works properly with an overridden container :type" do
      naked_executable = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/naked-executable.rb")

      Hbc::Installer.new(naked_executable).install

      expect(Hbc.caskroom.join("naked-executable", naked_executable.version, "naked_executable")).to be_a_file
    end

    it "works fine with a nested container" do
      nested_app = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/nested-app.rb")

      Hbc::Installer.new(nested_app).install

      expect(Hbc.appdir.join("MyNestedApp.app")).to be_a_directory
    end

    it "generates and finds a timestamped metadata directory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      Hbc::Installer.new(caffeine).install

      m_path = caffeine.metadata_timestamped_path(timestamp: :now, create: true)
      expect(caffeine.metadata_timestamped_path(timestamp: :latest)).to eq(m_path)
    end

    it "generates and finds a metadata subdirectory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      Hbc::Installer.new(caffeine).install

      subdir_name = "Casks"
      m_subdir = caffeine.metadata_subdir(subdir_name, timestamp: :now, create: true)
      expect(caffeine.metadata_subdir(subdir_name, timestamp: :latest)).to eq(m_subdir)
    end
  end

  describe "uninstall" do
    it "fully uninstalls a Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
      installer = Hbc::Installer.new(caffeine)

      installer.install
      installer.uninstall

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version, "Caffeine.app")).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).not_to be_a_directory
      expect(Hbc.caskroom.join("local-caffeine")).not_to be_a_directory
    end

    it "uninstalls all versions if force is set" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
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
