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
        when "10.12" then "9.2"
        when "10.13" then "10.1"
        when "10.14" then "10.1"
        else
          raise "macOS '#{MacOS.version}' is invalid" unless OS::Mac.prerelease?

          # Default to newest known version of Xcode for unreleased macOS versions.
          "10.1"
        end
      end

      def minimum_version
        case MacOS.version
        when "10.14" then "10.0"
        when "10.13" then "9.0"
        when "10.12" then "8.0"
        else "2.0"
        end
      end

      def below_minimum_version?
        return false unless installed?

        version < minimum_version
      end

      def latest_sdk_version?
        OS::Mac.version == OS::Mac.latest_sdk_version
      end

      def needs_clt_installed?
        return false if latest_sdk_version?

        without_clt?
      end

      def outdated?
        return false unless installed?

        version < latest_version
      end

      def without_clt?
        version >= "4.3" && !MacOS::CLT.installed?
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
        return if version < "4.3"

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

      def sdk(v = nil)
        @locator ||= XcodeSDKLocator.new

        @locator.sdk_if_applicable(v)
      end

      def sdk_path(v = nil)
        sdk(v)&.path
      end

      def update_instructions
        if MacOS.version >= "10.9" && !OS::Mac.prerelease?
          <<~EOS
            Xcode can be updated from the App Store.
          EOS
        else
          <<~EOS
            Xcode can be updated from
              https://developer.apple.com/download/more/
          EOS
        end
      end

      def version
        # may return a version string
        # that is guessed based on the compiler, so do not
        # use it in order to check if Xcode is installed.
        if @version ||= detect_version
          ::Version.new @version
        else
          ::Version::NULL
        end
      end

      def detect_version
        # This is a separate function as you can't cache the value out of a block
        # if return is used in the middle, which we do many times in here.
        return if !MacOS::Xcode.installed? && !MacOS::CLT.installed?

        %W[
          #{prefix}/usr/bin/xcodebuild
          #{which("xcodebuild")}
        ].uniq.each do |xcodebuild_path|
          next unless File.executable? xcodebuild_path

          xcodebuild_output = Utils.popen_read(xcodebuild_path, "-version")
          next unless $CHILD_STATUS.success?

          xcode_version = xcodebuild_output[/Xcode (\d+(\.\d+)*)/, 1]
          return xcode_version if xcode_version

          # Xcode 2.x's xcodebuild has a different version string
          case xcodebuild_output[/DevToolsCore-(\d+\.\d)/, 1]
          when "515.0" then return "2.0"
          when "798.0" then return "2.5"
          end
        end

        detect_version_from_clang_version
      end

      def detect_version_from_clang_version
        return "dunno" if DevelopmentTools.clang_version.null?

        # This logic provides a fake Xcode version based on the
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
        when 90      then "9.2"
        when 91      then "9.4"
        when 100     then "10.1"
        else              "10.1"
        end
      end

      def provides_gcc?
        version < "4.3"
      end

      def default_prefix?
        if version < "4.3"
          prefix.to_s.start_with? "/Developer"
        else
          prefix.to_s == "/Applications/Xcode.app/Contents/Developer"
        end
      end
    end

    module CLT
      module_function

      STANDALONE_PKG_ID = "com.apple.pkg.DeveloperToolsCLILeo".freeze
      FROM_XCODE_PKG_ID = "com.apple.pkg.DeveloperToolsCLI".freeze
      # The original Mavericks CLT package ID
      EXECUTABLE_PKG_ID = "com.apple.pkg.CLTools_Executables".freeze
      MAVERICKS_NEW_PKG_ID = "com.apple.pkg.CLTools_Base".freeze # obsolete
      PKG_PATH = "/Library/Developer/CommandLineTools".freeze
      HEADER_PKG_PATH =
        "/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_:macos_version.pkg".freeze
      HEADER_PKG_ID = "com.apple.pkg.macOS_SDK_headers_for_macOS_10.14".freeze

      # Returns true even if outdated tools are installed, e.g.
      # tools from Xcode 4.x on 10.9
      def installed?
        !version.null?
      end

      def separate_header_package?
        version >= "10"
      end

      def provides_sdk?
        version >= "8"
      end

      def headers_installed?
        if !separate_header_package?
          installed?
        else
          headers_version == version
        end
      end

      def sdk(v = nil)
        @locator ||= CLTSDKLocator.new

        @locator.sdk_if_applicable(v)
      end

      def sdk_path(v = nil)
        sdk(v)&.path
      end

      def update_instructions
        if MacOS.version >= "10.14"
          <<~EOS
            Update them from Software Update in System Preferences.
          EOS
        elsif MacOS.version >= "10.9"
          <<~EOS
            Update them from Software Update in the App Store.
          EOS
        elsif MacOS.version == "10.8" || MacOS.version == "10.7"
          <<~EOS
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
        when "10.14" then "1000.10.44.2"
        when "10.13" then "1000.10.44.2"
        when "10.12" then "900.0.39.2"
        when "10.11" then "800.0.42.1"
        when "10.10" then "700.1.81"
        when "10.9"  then "600.0.57"
        when "10.8"  then "503.0.40"
        else              "425.0.28"
        end
      end

      def minimum_version
        case MacOS.version
        when "10.14" then "10.0.0"
        when "10.13" then "9.0.0"
        when "10.12" then "8.0.0"
        else              "1.0.0"
        end
      end

      def below_minimum_version?
        # Lion was the first version of OS X to ship with a CLT
        return false if MacOS.version < :lion
        return false unless installed?

        version < minimum_version
      end

      def outdated?
        clang_version = detect_clang_version
        return false unless clang_version

        ::Version.new(clang_version) < latest_version
      end

      def detect_clang_version
        # Lion was the first version of OS X to ship with a CLT
        return if MacOS.version < :lion

        path = if MacOS.version >= :mavericks
          "#{PKG_PATH}/usr/bin/clang"
        else
          "/usr/bin/clang"
        end

        version_output = Utils.popen_read("#{path} --version")
        version_output[/clang-(\d+\.\d+\.\d+(\.\d+)?)/, 1]
      end

      # Version string (a pretty long one) of the CLT package.
      # Note, that different ways to install the CLTs lead to different
      # version numbers.
      def version
        if @version ||= detect_version
          ::Version.new @version
        else
          ::Version::NULL
        end
      end

      # Version string of the header package, which is a
      # separate package as of macOS 10.14.
      def headers_version
        if !separate_header_package?
          version
        else
          @header_version ||= MacOS.pkgutil_info(HEADER_PKG_ID)[/version: (.+)$/, 1]
          return ::Version::NULL unless @header_version

          ::Version.new(@header_version)
        end
      end

      def detect_version
        # CLT isn't a distinct entity pre-4.3, and pkgutil doesn't exist
        # at all on Tiger, so just count it as installed if Xcode is installed
        if MacOS::Xcode.installed? && MacOS::Xcode.version < "3.0"
          return MacOS::Xcode.version
        end

        version = nil
        [EXECUTABLE_PKG_ID, MAVERICKS_NEW_PKG_ID, STANDALONE_PKG_ID, FROM_XCODE_PKG_ID].each do |id|
          if MacOS.version >= :mavericks
            next unless File.exist?("#{PKG_PATH}/usr/bin/clang")
          end
          version = MacOS.pkgutil_info(id)[/version: (.+)$/, 1]
          break if version
        end
        version
      end
    end
  end
end
