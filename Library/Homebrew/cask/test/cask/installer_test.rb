require "test_helper"

describe Hbc::Installer do
  describe "install" do
    let(:empty_depends_on_stub) {
      stub(formula: [], cask: [], macos: nil, arch: nil, x11: nil)
    }

    it "downloads and installs a nice fresh Cask" do
      caffeine = Hbc.load("local-caffeine")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      dest_path = Hbc.caskroom.join("local-caffeine", caffeine.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("Caffeine.app")
      application.must_be :directory?
    end

    it "works with dmg-based Casks" do
      asset = Hbc.load("container-dmg")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-dmg", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container")
      file.must_be :file?
    end

    it "works with tar-gz-based Casks" do
      asset = Hbc.load("container-tar-gz")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-tar-gz", asset.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("container")
      application.must_be :file?
    end

    it "works with cab-based Casks" do
      skip("cabextract not installed") if which("cabextract").nil?
      asset = Hbc.load("container-cab")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-cab", asset.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("container")
      application.must_be :file?
    end

    it "works with Adobe AIR-based Casks" do
      skip("Adobe AIR not installed") unless Hbc::Container::Air.installer_exist?
      asset = Hbc.load("container-air")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-air", asset.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("container.app")
      application.must_be :directory?
    end

    it "works with 7z-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc.load("container-7z")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-7z", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container")
      file.must_be :file?
    end

    it "works with xar-based Casks" do
      asset = Hbc.load("container-xar")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-xar", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container")
      file.must_be :file?
    end

    it "works with Stuffit-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc.load("container-sit")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-sit", asset.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("container")
      application.must_be :file?
    end

    it "works with RAR-based Casks" do
      skip("unar not installed") if which("unar").nil?
      asset = Hbc.load("container-rar")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-rar", asset.version)
      dest_path.must_be :directory?
      application = Hbc.appdir.join("container")
      application.must_be :file?
    end

    it "works with pure bzip2-based Casks" do
      asset = Hbc.load("container-bzip2")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-bzip2", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container-bzip2--#{asset.version}")
      file.must_be :file?
    end

    it "works with pure gzip-based Casks" do
      asset = Hbc.load("container-gzip")

      shutup do
        Hbc::Installer.new(asset).install
      end

      dest_path = Hbc.caskroom.join("container-gzip", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container")
      file.must_be :file?
    end

    it "works with pure xz-based Casks" do
      skip("unxz not installed") if which("unxz").nil?
      asset = Hbc.load("container-xz")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-xz", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container-xz--#{asset.version}")
      file.must_be :file?
    end

    it "works with lzma-based Casks" do
      skip("unlzma not installed") if which("unlzma").nil?
      asset = Hbc.load("container-lzma")

      asset.stub :depends_on, empty_depends_on_stub do
        shutup do
          Hbc::Installer.new(asset).install
        end
      end

      dest_path = Hbc.caskroom.join("container-lzma", asset.version)
      dest_path.must_be :directory?
      file = Hbc.appdir.join("container-lzma--#{asset.version}")
      file.must_be :file?
    end

    it "blows up on a bad checksum" do
      bad_checksum = Hbc.load("bad-checksum")
      lambda {
        shutup do
          Hbc::Installer.new(bad_checksum).install
        end
      }.must_raise(Hbc::CaskSha256MismatchError)
    end

    it "blows up on a missing checksum" do
      missing_checksum = Hbc.load("missing-checksum")
      lambda {
        shutup do
          Hbc::Installer.new(missing_checksum).install
        end
      }.must_raise(Hbc::CaskSha256MissingError)
    end

    it "installs fine if sha256 :no_check is used" do
      no_checksum = Hbc.load("no-checksum")

      shutup do
        Hbc::Installer.new(no_checksum).install
      end

      no_checksum.must_be :installed?
    end

    it "fails to install if sha256 :no_check is used with --require-sha" do
      no_checksum = Hbc.load("no-checksum")
      lambda {
        Hbc::Installer.new(no_checksum, require_sha: true).install
      }.must_raise(Hbc::CaskNoShasumError)
    end

    it "installs fine if sha256 :no_check is used with --require-sha and --force" do
      no_checksum = Hbc.load("no-checksum")

      shutup do
        Hbc::Installer.new(no_checksum, require_sha: true, force: true).install
      end

      no_checksum.must_be :installed?
    end

    it "prints caveats if they're present" do
      with_caveats = Hbc.load("with-caveats")
      lambda {
        Hbc::Installer.new(with_caveats).install
      }.must_output(/Here are some things you might want to know/)
      with_caveats.must_be :installed?
    end

    it "prints installer :manual instructions when present" do
      with_installer_manual = Hbc.load("with-installer-manual")
      lambda {
        Hbc::Installer.new(with_installer_manual).install
      }.must_output(/To complete the installation of Cask with-installer-manual, you must also\nrun the installer at\n\n  '#{with_installer_manual.staged_path.join('Caffeine.app')}'/)
      with_installer_manual.must_be :installed?
    end

    it "does not extract __MACOSX directories from zips" do
      with_macosx_dir = Hbc.load("with-macosx-dir")

      shutup do
        Hbc::Installer.new(with_macosx_dir).install
      end

      with_macosx_dir.staged_path.join("__MACOSX").wont_be :directory?
    end

    it "installer method raises an exception when already-installed Casks which auto-update are attempted" do
      auto_updates = Hbc.load("auto-updates")
      auto_updates.installed?.must_equal false
      installer = Hbc::Installer.new(auto_updates)

      shutup do
        installer.install
      end

      lambda {
        installer.install
      }.must_raise(Hbc::CaskAlreadyInstalledAutoUpdatesError)
    end

    it "allows already-installed Casks which auto-update to be installed if force is provided" do
      auto_updates = Hbc.load("auto-updates")
      auto_updates.installed?.must_equal false

      shutup do
        Hbc::Installer.new(auto_updates).install
      end

      shutup do
        Hbc::Installer.new(auto_updates, force: true).install
      end # wont_raise
    end

    # unlike the CLI, the internal interface throws exception on double-install
    it "installer method raises an exception when already-installed Casks are attempted" do
      transmission = Hbc.load("local-transmission")
      transmission.installed?.must_equal false
      installer = Hbc::Installer.new(transmission)

      shutup do
        installer.install
      end

      lambda {
        installer.install
      }.must_raise(Hbc::CaskAlreadyInstalledError)
    end

    it "allows already-installed Casks to be installed if force is provided" do
      transmission = Hbc.load("local-transmission")
      transmission.installed?.must_equal false

      shutup do
        Hbc::Installer.new(transmission).install
      end

      shutup do
        Hbc::Installer.new(transmission, force: true).install
      end # wont_raise
    end

    it "works naked-pkg-based Casks" do
      naked_pkg = Hbc.load("container-pkg")

      shutup do
        Hbc::Installer.new(naked_pkg).install
      end

      dest_path = Hbc.caskroom.join("container-pkg", naked_pkg.version)
      pkg = dest_path.join("container.pkg")
      pkg.must_be :file?
    end

    it "works properly with an overridden container :type" do
      naked_executable = Hbc.load("naked-executable")

      shutup do
        Hbc::Installer.new(naked_executable).install
      end

      dest_path = Hbc.caskroom.join("naked-executable", naked_executable.version)
      executable = dest_path.join("naked_executable")
      executable.must_be :file?
    end

    it "works fine with a nested container" do
      nested_app = Hbc.load("nested-app")

      shutup do
        Hbc::Installer.new(nested_app).install
      end

      dest_path = Hbc.appdir.join("MyNestedApp.app")
      dest_path.must_be :directory?
    end

    it "generates and finds a timestamped metadata directory for an installed Cask" do
      caffeine = Hbc.load("local-caffeine")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      m_path = caffeine.metadata_path(:now, true)
      caffeine.metadata_path(:now, false).must_equal(m_path)
      caffeine.metadata_path(:latest).must_equal(m_path)
    end

    it "generates and finds a metadata subdirectory for an installed Cask" do
      caffeine = Hbc.load("local-caffeine")

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      subdir_name = "Casks"
      m_subdir = caffeine.metadata_subdir(subdir_name, :now, true)
      caffeine.metadata_subdir(subdir_name, :now, false).must_equal(m_subdir)
      caffeine.metadata_subdir(subdir_name, :latest).must_equal(m_subdir)
    end
  end

  describe "uninstall" do
    it "fully uninstalls a Cask" do
      caffeine = Hbc.load("local-caffeine")
      installer = Hbc::Installer.new(caffeine)

      shutup do
        installer.install
        installer.uninstall
      end

      Hbc.caskroom.join("local-caffeine", caffeine.version, "Caffeine.app").wont_be :directory?
      Hbc.caskroom.join("local-caffeine", caffeine.version).wont_be :directory?
      Hbc.caskroom.join("local-caffeine").wont_be :directory?
    end

    it "uninstalls all versions if force is set" do
      caffeine = Hbc.load("local-caffeine")
      mutated_version = caffeine.version + ".1"

      shutup do
        Hbc::Installer.new(caffeine).install
      end

      Hbc.caskroom.join("local-caffeine", caffeine.version).must_be :directory?
      Hbc.caskroom.join("local-caffeine", mutated_version).wont_be  :directory?
      FileUtils.mv(Hbc.caskroom.join("local-caffeine", caffeine.version), Hbc.caskroom.join("local-caffeine", mutated_version))
      Hbc.caskroom.join("local-caffeine", caffeine.version).wont_be :directory?
      Hbc.caskroom.join("local-caffeine", mutated_version).must_be  :directory?

      shutup do
        Hbc::Installer.new(caffeine, force: true).uninstall
      end

      Hbc.caskroom.join("local-caffeine", caffeine.version).wont_be :directory?
      Hbc.caskroom.join("local-caffeine", mutated_version).wont_be  :directory?
      Hbc.caskroom.join("local-caffeine").wont_be :directory?
    end
  end
end
