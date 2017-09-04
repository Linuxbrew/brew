module OS
  module Mac
    module Xcode
      module_function

      DEFAULT_BUNDLE_PATH = Pathname.new("/Applications/Xcode.app").freeze
      BUNDLE_ID = "com.apple.dt.Xcode".freeze
      OLD_BUNDLE_ID = "com.apple.Xcode".freeze

      def latest_version
        case MacOS.version
        when "10.4"  then "2.5"
        when "10.5"  then "3.1.4"
        when "10.6"  then "3.2.6"
        when "10.7"  then "4.6.3"
        when "10.8"  then "5.1.1"
        when "10.9"  then "6.2"
        when "10.10" then "7.2.1"
        when "10.11" then "8.2.1"
        when "10.12" then "8.3.3"
        when "10.13" then "9.0"
        else
          raise "macOS '#{MacOS.version}' is invalid" unless OS::Mac.prerelease?

          # Default to newest known version of Xcode for unreleased macOS versions.
          "9.0"
        end
      end

      def minimum_version
        case MacOS.version
        when "10.13" then "9.0"
        when "10.12" then "8.0"
        else "2.0"
        end
      end

      def below_minimum_version?
        version < minimum_version
      end

      def outdated?
        Version.new(version) < latest_version
      end

      def without_clt?
        installed? && Version.new(version) >= "4.3" && !MacOS::CLT.installed?
      end

      # Returns a Pathname object corresponding to Xcode.app's Developer
      # directory or nil if Xcode.app is not installed
      def prefix
        @prefix ||=
          begin
            dir = MacOS.active_developer_dir

            if dir.empty? || dir == CLT::PKG_PATH || !File.directory?(dir)
              path = bundle_path
              path/"Contents/Developer" if path
            else
              # Use cleanpath to avoid pathological trailing slash
              Pathname.new(dir).cleanpath
            end
          end
      end

      def toolchain_path
        return unless installed?
        return if Version.new(version) < "4.3"
        Pathname.new("#{prefix}/Toolchains/XcodeDefault.xctoolchain")
      end

      def bundle_path
        # Use the default location if it exists.
        return DEFAULT_BUNDLE_PATH if DEFAULT_BUNDLE_PATH.exist?

        # Ask Spotlight where Xcode is. If the user didn't install the
        # helper tools and installed Xcode in a non-conventional place, this
        # is our only option. See: https://superuser.com/questions/390757
        MacOS.app_with_bundle_id(BUNDLE_ID, OLD_BUNDLE_ID)
      end

      def installed?
        !prefix.nil?
      end

      def update_instructions
        if MacOS.version >= "10.9" && !OS::Mac.prerelease?
          <<-EOS.undent
            Xcode can be updated from the App Store.
          EOS
        else
          <<-EOS.undent
            Xcode can be updated from
              https://developer.apple.com/download/more/
          EOS
        end
      end

      def version
        # may return a version string
        # that is guessed based on the compiler, so do not
        # use it in order to check if Xcode is installed.
        @version ||= uncached_version
      end

      def uncached_version
        # This is a separate function as you can't cache the value out of a block
        # if return is used in the middle, which we do many times in here.

        return "0" unless OS.mac?

        return nil if !MacOS::Xcode.installed? && !MacOS::CLT.installed?

        %W[
          #{prefix}/usr/bin/xcodebuild
          #{which("xcodebuild")}
        ].uniq.each do |xcodebuild_path|
          next unless File.executable? xcodebuild_path
          xcodebuild_output = Utils.popen_read(xcodebuild_path, "-version")
          next unless $CHILD_STATUS.success?

          xcode_version = xcodebuild_output[/Xcode (\d(\.\d)*)/, 1]
          return xcode_version if xcode_version

          # Xcode 2.x's xcodebuild has a different version string
          case xcodebuild_output[/DevToolsCore-(\d+\.\d)/, 1]
          when "515.0" then return "2.0"
          when "798.0" then return "2.5"
          end
        end

        # The remaining logic provides a fake Xcode version based on the
        # installed CLT version. This is useful as they are packaged
        # simultaneously so workarounds need to apply to both based on their
        # comparable version.
        case (DevelopmentTools.clang_version.to_f * 10).to_i
        when 0       then "dunno"
        when 1..14   then "3.2.2"
        when 15      then "3.2.4"
        when 16      then "3.2.5"
        when 17..20  then "4.0"
        when 21      then "4.1"
        when 22..30  then "4.2"
        when 31      then "4.3"
        when 40      then "4.4"
        when 41      then "4.5"
        when 42      then "4.6"
        when 50      then "5.0"
        when 51      then "5.1"
        when 60      then "6.0"
        when 61      then "6.1"
        when 70      then "7.0"
        when 73      then "7.3"
        when 80      then "8.0"
        when 81      then "8.3"
        when 90      then "9.0"
        else "9.0"
        end
      end

      def provides_gcc?
        installed? && Version.new(version) < "4.3"
      end

      def provides_cvs?
        installed? && Version.new(version) < "5.0"
      end

      def default_prefix?
        if Version.new(version) < "4.3"
          prefix.to_s.start_with? "/Developer"
        else
          prefix.to_s == "/Applications/Xcode.app/Contents/Developer"
        end
      end

      class Version < ::Version
        def <=>(other)
          super(Version.new(other))
        end
      end
    end

    module CLT
      extend self

      STANDALONE_PKG_ID = "com.apple.pkg.DeveloperToolsCLILeo".freeze
      FROM_XCODE_PKG_ID = "com.apple.pkg.DeveloperToolsCLI".freeze
      MAVERICKS_PKG_ID = "com.apple.pkg.CLTools_Executables".freeze
      MAVERICKS_NEW_PKG_ID = "com.apple.pkg.CLTools_Base".freeze # obsolete
      PKG_PATH = "/Library/Developer/CommandLineTools".freeze

      # Returns true even if outdated tools are installed, e.g.
      # tools from Xcode 4.x on 10.9
      def installed?
        !detect_version.nil?
      end

      def update_instructions
        if MacOS.version >= "10.9"
          <<-EOS.undent
            Update them from Software Update in the App Store.
          EOS
        elsif MacOS.version == "10.8" || MacOS.version == "10.7"
          <<-EOS.undent
            The standalone package can be obtained from
              https://developer.apple.com/download/more/
            or it can be installed via Xcode's preferences.
          EOS
        end
      end

      def latest_version
        # As of Xcode 8 CLT releases are no longer in sync with Xcode releases
        # on the older supported platform for that Xcode release, i.e there's no
        # CLT package for 10.11 that contains the Clang version from Xcode 8.
        case MacOS.version
        when "10.13" then "900.0.35"
        when "10.12" then "802.0.42"
        when "10.11" then "800.0.42.1"
        when "10.10" then "700.1.81"
        when "10.9"  then "600.0.57"
        when "10.8"  then "503.0.40"
        else
          "425.0.28"
        end
      end

      def minimum_version
        case MacOS.version
        when "10.13" then "9.0.0"
        when "10.12" then "8.0.0"
        else "1.0.0"
        end
      end

      def below_minimum_version?
        # Lion was the first version of OS X to ship with a CLT
        return false if MacOS.version < :lion
        version < minimum_version
      end

      def outdated?
        # Lion was the first version of OS X to ship with a CLT
        return false if MacOS.version < :lion

        if MacOS.version >= :mavericks
          version = Utils.popen_read("#{PKG_PATH}/usr/bin/clang --version")
        else
          version = Utils.popen_read("/usr/bin/clang --version")
        end
        version = version[/clang-(\d+\.\d+\.\d+(\.\d+)?)/, 1] || "0"
        Xcode::Version.new(version) < latest_version
      end

      # Version string (a pretty long one) of the CLT package.
      # Note, that different ways to install the CLTs lead to different
      # version numbers.
      def version
        @version ||= detect_version
      end

      def detect_version
        # CLT isn't a distinct entity pre-4.3, and pkgutil doesn't exist
        # at all on Tiger, so just count it as installed if Xcode is installed
        if MacOS::Xcode.installed? && Xcode::Version.new(MacOS::Xcode.version) < "3.0"
          return MacOS::Xcode.version
        end

        [MAVERICKS_PKG_ID, MAVERICKS_NEW_PKG_ID, STANDALONE_PKG_ID, FROM_XCODE_PKG_ID].find do |id|
          if MacOS.version >= :mavericks
            next unless File.exist?("#{PKG_PATH}/usr/bin/clang")
          end
          version = MacOS.pkgutil_info(id)[/version: (.+)$/, 1]
          return version if version
        end
      end
    end
  end
end
