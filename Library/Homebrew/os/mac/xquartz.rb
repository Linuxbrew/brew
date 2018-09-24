module OS
  module Mac
    X11 = XQuartz = Module.new

    module XQuartz
      module_function

      DEFAULT_BUNDLE_PATH = Pathname.new("Applications/Utilities/XQuartz.app").freeze
      FORGE_BUNDLE_ID = "org.macosforge.xquartz.X11".freeze
      APPLE_BUNDLE_ID = "org.x.X11".freeze
      FORGE_PKG_ID = "org.macosforge.xquartz.pkg".freeze

      PKGINFO_VERSION_MAP = {
        "2.6.34" => "2.6.3",
        "2.7.4"  => "2.7.0",
        "2.7.14" => "2.7.1",
        "2.7.28" => "2.7.2",
        "2.7.32" => "2.7.3",
        "2.7.43" => "2.7.4",
        "2.7.50" => "2.7.5_rc1",
        "2.7.51" => "2.7.5_rc2",
        "2.7.52" => "2.7.5_rc3",
        "2.7.53" => "2.7.5_rc4",
        "2.7.54" => "2.7.5",
        "2.7.61" => "2.7.6",
        "2.7.73" => "2.7.7",
        "2.7.86" => "2.7.8",
        "2.7.94" => "2.7.9",
        "2.7.108" => "2.7.10",
        "2.7.112" => "2.7.11",
      }.freeze

      # This returns the version number of XQuartz, not of the upstream X.org.
      # The X11.app distributed by Apple is also XQuartz, and therefore covered
      # by this method.
      def version
        if @version ||= detect_version
          ::Version.new @version
        else
          ::Version::NULL
        end
      end

      def detect_version
        if (path = bundle_path) && path.exist? && (version = version_from_mdls(path))
          version
        elsif prefix.to_s == "/usr/X11" || prefix.to_s == "/usr/X11R6"
          guess_system_version
        else
          version_from_pkgutil
        end
      end

      def minimum_version
        version = guess_system_version
        return version unless version == "dunno"

        # Update this a little later than latest_version to give people
        # time to upgrade.
        "2.7.11"
      end

      # https://xquartz.macosforge.org/trac/wiki
      # https://xquartz.macosforge.org/trac/wiki/Releases
      def latest_version
        case MacOS.version
        when "10.5"
          "2.6.3"
        else
          "2.7.11"
        end
      end

      def bundle_path
        # Use the default location if it exists.
        return DEFAULT_BUNDLE_PATH if DEFAULT_BUNDLE_PATH.exist?

        # Ask Spotlight where XQuartz is. If the user didn't install XQuartz
        # in the conventional place, this is our only option.
        MacOS.app_with_bundle_id(FORGE_BUNDLE_ID, APPLE_BUNDLE_ID)
      end

      def version_from_mdls(path)
        version = Utils.popen_read(
          "/usr/bin/mdls", "-raw", "-nullMarker", "", "-name", "kMDItemVersion", path.to_s
        ).strip
        version unless version.empty?
      end

      # The XQuartz that Apple shipped in OS X through 10.7 does not have a
      # pkg-util entry, so if Spotlight indexing is disabled we must make an
      # educated guess as to what version is installed.
      def guess_system_version
        case MacOS.version
        when "10.4" then "1.1.3"
        when "10.5" then "2.1.6"
        when "10.6" then "2.3.6"
        when "10.7" then "2.6.3"
        else "dunno"
        end
      end

      # Upstream XQuartz *does* have a pkg-info entry, so if we can't get it
      # from mdls, we can try pkgutil. This is very slow.
      def version_from_pkgutil
        str = MacOS.pkgutil_info(FORGE_PKG_ID)[/version: (\d\.\d\.\d+)$/, 1]
        PKGINFO_VERSION_MAP.fetch(str, str)
      end

      def provided_by_apple?
        [FORGE_BUNDLE_ID, APPLE_BUNDLE_ID].find do |id|
          MacOS.app_with_bundle_id(id)
        end == APPLE_BUNDLE_ID
      end

      # This should really be private, but for compatibility reasons it must
      # remain public. New code should use MacOS::X11.bin, MacOS::X11.lib and
      # MacOS::X11.include instead, as that accounts for Xcode-only systems.
      def prefix
        @prefix ||= if Pathname.new("/opt/X11/lib/libpng.dylib").exist?
          Pathname.new("/opt/X11")
        elsif Pathname.new("/usr/X11/lib/libpng.dylib").exist?
          Pathname.new("/usr/X11")
        # X11 doesn't include libpng on Tiger
        elsif Pathname.new("/usr/X11R6/lib/libX11.dylib").exist?
          Pathname.new("/usr/X11R6")
        end
      end

      def installed?
        !version.null? && !prefix.nil?
      end

      def outdated?
        return false unless installed?
        return false if provided_by_apple?

        version < latest_version
      end

      # If XQuartz and/or the CLT are installed, headers will be found under
      # /opt/X11/include or /usr/X11/include. For Xcode-only systems, they are
      # found in the SDK, so we use sdk_path for both the headers and libraries.
      # Confusingly, executables (e.g. config scripts) are only found under
      # /opt/X11/bin or /usr/X11/bin in all cases.
      def effective_prefix
        if provided_by_apple? && Xcode.without_clt?
          Pathname.new("#{OS::Mac.sdk_path}/usr/X11")
        else
          prefix
        end
      end

      def bin
        prefix/"bin"
      end

      def include
        effective_prefix/"include"
      end

      def lib
        effective_prefix/"lib"
      end

      def share
        prefix/"share"
      end
    end
  end
end
