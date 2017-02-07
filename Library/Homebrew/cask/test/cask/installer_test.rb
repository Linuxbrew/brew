require "test_helper"

describe Hbc::Installer do
  describe "install" do
    let(:empty_depends_on_stub) {
      stub(formula: [], cask: [], macos: nil, arch: nil, x11: nil)
    }

    it "downloads and installs a nice fresh Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).must_be :directory?
      expect(Hbc.appdir.join("Caffeine.app")).must_be :directory?
    end

    it "works with dmg-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-dmg.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-dmg", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with tar-gz-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-tar-gz.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-tar-gz", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with cab-based Casks" do
      skip("cabextract not installed") if which("cabextract").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-cab.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-cab", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with Adobe AIR-based Casks" do
      skip("Adobe AIR not installed") unless Hbc::Container::Air.installer_exist?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-air.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-air", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container.app")).must_be :directory?
    end

    it "works with 7z-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-7z.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-7z", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with xar-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-xar.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-xar", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with Stuffit-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-sit.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-sit", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with RAR-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-rar.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-rar", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with pure bzip2-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-bzip2.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-bzip2", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container-bzip2--#{asset.version}")).must_be :file?
    end

    it "works with pure gzip-based Casks" do
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-gzip.rb")

      shutup do
        Hbc::Installer.new(asset).install
      end

      expect(Hbc.caskroom.join("container-gzip", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container")).must_be :file?
    end

    it "works with pure xz-based Casks" do
      skip("unxz not installed") if which("unxz").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-xz.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-xz", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container-xz--#{asset.version}")).must_be :file?
    end

    it "works with lzma-based Casks" do
      skip("unlzma not installed") if which("unlzma").nil?
      asset = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-lzma.rb")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      expect(Hbc.caskroom.join("container-lzma", asset.version)).must_be :directory?
      expect(Hbc.appdir.join("container-lzma--#{asset.version}")).must_be :file?
    end

    it "blows up on a bad checksum" do
      bad_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/bad-checksum.rb")
      expect {
        shutup do
          Hbc::Installer.new(bad_checksum).install
        end
      }.must_raise(Hbc::CaskSha256MismatchError)
    end

    it "blows up on a missing checksum" do
      missing_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/missing-checksum.rb")
      expect {
        shutup do
          Hbc::Installer.new(missing_checksum).install
        end
      }.must_raise(Hbc::CaskSha256MissingError)
    end

    it "installs fine if sha256 :no_check is used" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")

      shutup do
        Hbc::Installer.new(no_checksum).install
      end

      expect(no_checksum).must_be :installed?
    end

    it "fails to install if sha256 :no_check is used with --require-sha" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")
      expect {
        Hbc::Installer.new(no_checksum, require_sha: true).install
      }.must_raise(Hbc::CaskNoShasumError)
    end

    it "installs fine if sha256 :no_check is used with --require-sha and --force" do
      no_checksum = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-checksum.rb")

      shutup do
        Hbc::Installer.new(no_checksum, require_sha: true, force: true).install
      end

      expect(no_checksum).must_be :installed?
    end

    it "prints caveats if they're present" do
      with_caveats = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-caveats.rb")

      expect {
        Hbc::Installer.new(with_caveats).install
      }.must_output(/Here are some things you might want to know/)

      expect(with_caveats).must_be :installed?
    end

    it "prints installer :manual instructions when present" do
      with_installer_manual = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installer-manual.rb")

      expect {
        Hbc::Installer.new(with_installer_manual).install
      }.must_output(/To complete the installation of Cask with-installer-manual, you must also\nrun the installer at\n\n  '#{with_installer_manual.staged_path.join('Caffeine.app')}'/)

      expect(with_installer_manual).must_be :installed?
    end

    it "does not extract __MACOSX directories from zips" do
      with_macosx_dir = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-macosx-dir.rb")

      shutup do
        Hbc::Installer.new(with_macosx_dir).install
      end

      expect(with_macosx_dir.staged_path.join("__MACOSX")).wont_be :directory?
    end

    it "installer method raises an exception when already-installed Casks which auto-update are attempted" do
      with_auto_updates = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/auto-updates.rb")

      expect(with_auto_updates).wont_be :installed?

      installer = Hbc::Installer.new(with_auto_updates)

      shutup do
        installer.install
      end

      expect {
        installer.install
      }.must_raise(Hbc::CaskAlreadyInstalledAutoUpdatesError)
    end

    it "allows already-installed Casks which auto-update to be installed if force is provided" do
      with_auto_updates = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/auto-updates.rb")

      expect(with_auto_updates).wont_be :installed?

      shutup do
        Hbc::Installer.new(with_auto_updates).install
      end

      shutup do
        Hbc::Installer.new(with_auto_updates, force: true).install
      end # wont_raise
    end

    # unlike the CLI, the internal interface throws exception on double-install
    it "installer method raises an exception when already-installed Casks are attempted" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      expect(transmission).wont_be :installed?

      installer = Hbc::Installer.new(transmission)

      shutup do
        installer.install
      end

      expect {
        installer.install
      }.must_raise(Hbc::CaskAlreadyInstalledError)
    end

    it "allows already-installed Casks to be installed if force is provided" do
      transmission = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")

      expect(transmission).wont_be :installed?

      shutup do
        Hbc::Installer.new(transmission).install
      end

      shutup do
        Hbc::Installer.new(transmission, force: true).install
      end # wont_raise
    end

    it "works naked-pkg-based Casks" do
      naked_pkg = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/container-pkg.rb")

      shutup do
        Hbc::Installer.new(naked_pkg).install
      end

      expect(Hbc.caskroom.join("container-pkg", naked_pkg.version, "container.pkg")).must_be :file?
    end

    it "works properly with an overridden container :type" do
      naked_executable = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/naked-executable.rb")

      shutup do
        Hbc::Installer.new(naked_executable).install
      end

      expect(Hbc.caskroom.join("naked-executable", naked_executable.version, "naked_executable")).must_be :file?
    end

    it "works fine with a nested container" do
      nested_app = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/nested-app.rb")

      shutup do
        Hbc::Installer.new(nested_app).install
      end

      expect(Hbc.appdir.join("MyNestedApp.app")).must_be :directory?
    end

    it "generates and finds a timestamped metadata directory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      m_path = caffeine.metadata_path(:now, true)
      expect(caffeine.metadata_path(:now, false)).must_equal(m_path)
      expect(caffeine.metadata_path(:latest)).must_equal(m_path)
    end

    it "generates and finds a metadata subdirectory for an installed Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      subdir_name = "Casks"
      m_subdir = caffeine.metadata_subdir(subdir_name, :now, true)
      expect(caffeine.metadata_subdir(subdir_name, :now, false)).must_equal(m_subdir)
      expect(caffeine.metadata_subdir(subdir_name, :latest)).must_equal(m_subdir)
    end
  end

  describe "uninstall" do
    it "fully uninstalls a Cask" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
      installer = Hbc::Installer.new(caffeine)

      shutup do
        installer.install
        installer.uninstall
      end

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version, "Caffeine.app")).wont_be :directory?
      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).wont_be :directory?
      expect(Hbc.caskroom.join("local-caffeine")).wont_be :directory?
    end

    it "uninstalls all versions if force is set" do
      caffeine = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
      mutated_version = caffeine.version + ".1"

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).must_be :directory?
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).wont_be  :directory?
      FileUtils.mv(Hbc.caskroom.join("local-caffeine", caffeine.version), Hbc.caskroom.join("local-caffeine", mutated_version))
      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).wont_be :directory?
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).must_be  :directory?

      shutup do
        Hbc::Installer.new(caffeine, force: true).uninstall
      end

      expect(Hbc.caskroom.join("local-caffeine", caffeine.version)).wont_be :directory?
      expect(Hbc.caskroom.join("local-caffeine", mutated_version)).wont_be  :directory?
      expect(Hbc.caskroom.join("local-caffeine")).wont_be :directory?
    end
  end
end
