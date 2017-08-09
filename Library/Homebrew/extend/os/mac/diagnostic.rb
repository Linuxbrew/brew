module Homebrew
  module Diagnostic
    class Checks
      def development_tools_checks
        %w[
          check_for_unsupported_macos
          check_for_bad_install_name_tool
          check_for_installed_developer_tools
          check_xcode_license_approved
          check_for_osx_gcc_installer
          check_xcode_8_without_clt_on_el_capitan
          check_xcode_up_to_date
          check_clt_up_to_date
          check_for_other_package_managers
        ].freeze
      end

      def fatal_development_tools_checks
        %w[
          check_xcode_minimum_version
          check_clt_minimum_version
        ].freeze
      end

      def build_error_checks
        (development_tools_checks + %w[
          check_for_unsupported_macos
        ]).freeze
      end

      def check_for_unsupported_macos
        return if ARGV.homebrew_developer?

        who = "We"
        if OS::Mac.prerelease?
          what = "pre-release version"
        elsif OS::Mac.outdated_release?
          who << " (and Apple)"
          what = "old version"
        else
          return
        end

        <<-EOS.undent
          You are using macOS #{MacOS.version}.
          #{who} do not provide support for this #{what}.
          You may encounter build failures or other breakages.
          Please create pull-requests instead of filing issues.
        EOS
      end

      def check_xcode_up_to_date
        return unless MacOS::Xcode.installed?
        return unless MacOS::Xcode.outdated?

        # Travis CI images are going to end up outdated so don't complain when
        # `brew test-bot` runs `brew doctor` in the CI for the Homebrew/brew
        # repository. This only needs to support whatever CI provider
        # Homebrew/brew is currently using.
        return if ENV["TRAVIS"]

        message = <<-EOS.undent
          Your Xcode (#{MacOS::Xcode.version}) is outdated.
          Please update to Xcode #{MacOS::Xcode.latest_version} (or delete it).
          #{MacOS::Xcode.update_instructions}
        EOS

        if OS::Mac.prerelease?
          current_path = Utils.popen_read("/usr/bin/xcode-select", "-p")
          message += <<-EOS.undent
            If #{MacOS::Xcode.latest_version} is installed, you may need to:
              sudo xcode-select --switch /Applications/Xcode.app
            Current developer directory is:
              #{current_path}
          EOS
        end
        message
      end

      def check_clt_up_to_date
        return unless MacOS::CLT.installed?
        return unless MacOS::CLT.outdated?

        # Travis CI images are going to end up outdated so don't complain when
        # `brew test-bot` runs `brew doctor` in the CI for the Homebrew/brew
        # repository. This only needs to support whatever CI provider
        # Homebrew/brew is currently using.
        return if ENV["TRAVIS"]

        <<-EOS.undent
          A newer Command Line Tools release is available.
          #{MacOS::CLT.update_instructions}
        EOS
      end

      def check_xcode_8_without_clt_on_el_capitan
        return unless MacOS::Xcode.without_clt?
        # Scope this to Xcode 8 on El Cap for now
        return unless MacOS.version == :el_capitan
        return unless MacOS::Xcode.version >= "8"

        <<-EOS.undent
          You have Xcode 8 installed without the CLT;
          this causes certain builds to fail on OS X El Capitan (10.11).
          Please install the CLT via:
            sudo xcode-select --install
        EOS
      end

      def check_xcode_minimum_version
        return unless MacOS::Xcode.installed?
        return unless MacOS::Xcode.below_minimum_version?

        <<-EOS.undent
          Your Xcode (#{MacOS::Xcode.version}) is too outdated.
          Please update to Xcode #{MacOS::Xcode.latest_version} (or delete it).
          #{MacOS::Xcode.update_instructions}
        EOS
      end

      def check_clt_minimum_version
        return unless MacOS::CLT.installed?
        return unless MacOS::CLT.below_minimum_version?

        <<-EOS.undent
          Your Command Line Tools are too outdated.
          #{MacOS::CLT.update_instructions}
        EOS
      end

      def check_for_osx_gcc_installer
        return unless MacOS.version < "10.7" || ((MacOS::Xcode.version || "0") > "4.1")
        return unless DevelopmentTools.clang_version == "2.1"

        fix_advice = if MacOS.version >= :mavericks
          "Please run `xcode-select --install` to install the CLT."
        elsif MacOS.version >= :lion
          "Please install the CLT or Xcode #{MacOS::Xcode.latest_version}."
        else
          "Please install Xcode #{MacOS::Xcode.latest_version}."
        end

        <<-EOS.undent
          You seem to have osx-gcc-installer installed.
          Homebrew doesn't support osx-gcc-installer. It causes many builds to fail and
          is an unlicensed distribution of really old Xcode files.
          #{fix_advice}
        EOS
      end

      def check_for_stray_developer_directory
        # if the uninstaller script isn't there, it's a good guess neither are
        # any troublesome leftover Xcode files
        uninstaller = Pathname.new("/Developer/Library/uninstall-developer-folder")
        return unless ((MacOS::Xcode.version || "0") >= "4.3") && uninstaller.exist?

        <<-EOS.undent
          You have leftover files from an older version of Xcode.
          You should delete them using:
            #{uninstaller}
        EOS
      end

      def check_for_bad_install_name_tool
        return if MacOS.version < "10.9"

        libs = Pathname.new("/usr/bin/install_name_tool").dynamically_linked_libraries

        # otool may not work, for example if the Xcode license hasn't been accepted yet
        return if libs.empty?
        return if libs.include? "/usr/lib/libxcselect.dylib"

        <<-EOS.undent
          You have an outdated version of /usr/bin/install_name_tool installed.
          This will cause binary package installations to fail.
          This can happen if you install osx-gcc-installer or RailsInstaller.
          To restore it, you must reinstall macOS or restore the binary from
          the OS packages.
        EOS
      end

      def check_for_other_package_managers
        ponk = MacOS.macports_or_fink
        return if ponk.empty?

        <<-EOS.undent
          You have MacPorts or Fink installed:
            #{ponk.join(", ")}

          This can cause trouble. You don't have to uninstall them, but you may want to
          temporarily move them out of the way, e.g.

            sudo mv /opt/local ~/macports
        EOS
      end

      def check_ruby_version
        ruby_version = "2.0"
        return if RUBY_VERSION[/\d\.\d/] == ruby_version

        <<-EOS.undent
          Ruby version #{RUBY_VERSION} is unsupported on #{MacOS.version}. Homebrew
          is developed and tested on Ruby #{ruby_version}, and may not work correctly
          on other Rubies. Patches are accepted as long as they don't cause breakage
          on supported Rubies.
        EOS
      end

      def check_xcode_prefix
        prefix = MacOS::Xcode.prefix
        return if prefix.nil?
        return unless prefix.to_s.include?(" ")

        <<-EOS.undent
          Xcode is installed to a directory with a space in the name.
          This will cause some formulae to fail to build.
        EOS
      end

      def check_xcode_prefix_exists
        prefix = MacOS::Xcode.prefix
        return if prefix.nil? || prefix.exist?

        <<-EOS.undent
          The directory Xcode is reportedly installed to doesn't exist:
            #{prefix}
          You may need to `xcode-select` the proper path if you have moved Xcode.
        EOS
      end

      def check_xcode_select_path
        return if MacOS::CLT.installed?
        return unless MacOS::Xcode.installed?
        return if File.file?("#{MacOS.active_developer_dir}/usr/bin/xcodebuild")

        path = MacOS::Xcode.bundle_path
        path = "/Developer" if path.nil? || !path.directory?
        <<-EOS.undent
          Your Xcode is configured with an invalid path.
          You should change it to the correct path:
            sudo xcode-select -switch #{path}
        EOS
      end

      def check_for_bad_curl
        return unless MacOS.version <= "10.8"
        return if Formula["curl"].installed?

        <<-EOS.undent
          The system curl on 10.8 and below is often incapable of supporting
          modern secure connections & will fail on fetching formulae.

          We recommend you:
            brew install curl
        EOS
      end

      def check_for_unsupported_curl_vars
        # Support for SSL_CERT_DIR seemed to be removed in the 10.10.5 update.
        return unless MacOS.version >= :yosemite
        return if ENV["SSL_CERT_DIR"].nil?

        <<-EOS.undent
          SSL_CERT_DIR support was removed from Apple's curl.
          If fetching formulae fails you should:
            unset SSL_CERT_DIR
          and remove it from #{Utils::Shell.profile} if present.
        EOS
      end

      def check_xcode_license_approved
        # If the user installs Xcode-only, they have to approve the
        # license or no "xc*" tool will work.
        return unless `/usr/bin/xcrun clang 2>&1` =~ /license/ && !$CHILD_STATUS.success?

        <<-EOS.undent
          You have not agreed to the Xcode license.
          Builds will fail! Agree to the license by opening Xcode.app or running:
            sudo xcodebuild -license
        EOS
      end

      def check_for_latest_xquartz
        return unless MacOS::XQuartz.version
        return if MacOS::XQuartz.provided_by_apple?

        installed_version = Version.create(MacOS::XQuartz.version)
        latest_version = Version.create(MacOS::XQuartz.latest_version)
        return if installed_version >= latest_version

        <<-EOS.undent
          Your XQuartz (#{installed_version}) is outdated.
          Please install XQuartz #{latest_version} (or delete the current version).
          XQuartz can be updated using Homebrew-Cask by running
            brew cask reinstall xquartz
        EOS
      end

      def check_for_beta_xquartz
        return unless MacOS::XQuartz.version
        return unless MacOS::XQuartz.version.include? "beta"

        <<-EOS.undent
          The following beta release of XQuartz is installed: #{MacOS::XQuartz.version}

          XQuartz beta releases include address sanitization, and do not work with
          all software; notably, wine will not work with beta releases of XQuartz.
          We recommend only installing stable releases of XQuartz.
        EOS
      end

      def check_filesystem_case_sensitive
        dirs_to_check = [
          HOMEBREW_PREFIX,
          HOMEBREW_REPOSITORY,
          HOMEBREW_CELLAR,
          HOMEBREW_TEMP,
        ]
        case_sensitive_dirs = dirs_to_check.select do |dir|
          # We select the dir as being case-sensitive if either the UPCASED or the
          # downcased variant is missing.
          # Of course, on a case-insensitive fs, both exist because the os reports so.
          # In the rare situation when the user has indeed a downcased and an upcased
          # dir (e.g. /TMP and /tmp) this check falsely thinks it is case-insensitive
          # but we don't care because: 1. there is more than one dir checked, 2. the
          # check is not vital and 3. we would have to touch files otherwise.
          upcased = Pathname.new(dir.to_s.upcase)
          downcased = Pathname.new(dir.to_s.downcase)
          dir.exist? && !(upcased.exist? && downcased.exist?)
        end
        return if case_sensitive_dirs.empty?

        volumes = Volumes.new
        case_sensitive_vols = case_sensitive_dirs.map do |case_sensitive_dir|
          volumes.get_mounts(case_sensitive_dir)
        end
        case_sensitive_vols.uniq!

        <<-EOS.undent
          The filesystem on #{case_sensitive_vols.join(",")} appears to be case-sensitive.
          The default macOS filesystem is case-insensitive. Please report any apparent problems.
        EOS
      end

      def check_homebrew_prefix
        return if HOMEBREW_PREFIX.to_s == "/usr/local"

        <<-EOS.undent
          Your Homebrew's prefix is not /usr/local.
          You can install Homebrew anywhere you want but some bottles (binary packages)
          can only be used with a /usr/local prefix and some formulae (packages)
          may not build correctly with a non-/usr/local prefix.
        EOS
      end

      def check_which_pkg_config
        binary = which "pkg-config"
        return if binary.nil?

        mono_config = Pathname.new("/usr/bin/pkg-config")
        if mono_config.exist? && mono_config.realpath.to_s.include?("Mono.framework")
          <<-EOS.undent
            You have a non-Homebrew 'pkg-config' in your PATH:
              /usr/bin/pkg-config => #{mono_config.realpath}

            This was most likely created by the Mono installer. `./configure` may
            have problems finding brew-installed packages using this other pkg-config.

            Mono no longer installs this file as of 3.0.4. You should
            `sudo rm /usr/bin/pkg-config` and upgrade to the latest version of Mono.
          EOS
        elsif binary.to_s != "#{HOMEBREW_PREFIX}/bin/pkg-config"
          <<-EOS.undent
            You have a non-Homebrew 'pkg-config' in your PATH:
              #{binary}

            `./configure` may have problems finding brew-installed packages using
            this other pkg-config.
          EOS
        end
      end
    end
  end
end
