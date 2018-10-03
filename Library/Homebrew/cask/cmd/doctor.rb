require "system_config"
require "cask/checkable"

module Cask
  class Cmd
    class Doctor < AbstractCommand
      include Checkable

      def initialize(*)
        super
        return if args.empty?

        raise ArgumentError, "#{self.class.command_name} does not take arguments."
      end

      def success?
        !(errors? || warnings?)
      end

      def summary_header
        "Cask's Doctor Checkup"
      end

      def run
        check_software_versions
        check_quarantine_support
        check_install_location
        check_staging_location
        check_taps
        check_load_path
        check_environment_variables

        puts summary unless success?
        raise CaskError, "There are some problems with your setup." unless success?
      end

      def check_software_versions
        ohai "Homebrew Version", HOMEBREW_VERSION
        ohai "macOS", MacOS.full_version
        ohai "SIP", self.class.check_sip
        ohai "Java", SystemConfig.describe_java
      end

      # This could be done by calling into Homebrew, but the situation
      # where "doctor" is needed is precisely the situation where such
      # things are less dependable.
      def check_install_location
        ohai "Homebrew Cask Install Location"

        locations = Dir.glob(HOMEBREW_CELLAR.join("brew-cask", "*")).reverse
        if locations.empty?
          puts self.class.none_string
        else
          locations.map do |l|
            add_error "Legacy install at #{l}. Run \"brew uninstall --force brew-cask\"."
            puts l
          end
        end
      end

      def check_staging_location
        ohai "Homebrew Cask Staging Location"

        path = Caskroom.path

        if path.exist? && !path.writable?
          add_error "The staging path #{user_tilde(path.to_s)} is not writable by the current user."
        end

        puts user_tilde(path.to_s)
      end

      def check_taps
        default_tap = Tap.default_cask_tap
        alt_taps = Tap.select { |t| t.cask_dir.exist? && t != default_tap }

        ohai "Homebrew Cask Taps:"
        [default_tap, *alt_taps].each do |tap|
          if tap.path.blank?
            puts none_string
          else
            puts "#{tap.path} (#{cask_count_for_tap(tap)})"
          end
        end
      end

      def check_load_path
        ohai "Contents of $LOAD_PATH"
        paths = $LOAD_PATH.map(&method(:user_tilde))

        if paths.empty?
          puts none_string
          add_error "$LOAD_PATH is empty"
        else
          puts paths
        end
      end

      def check_environment_variables
        ohai "Environment Variables"

        environment_variables = %w[
          RUBYLIB
          RUBYOPT
          RUBYPATH
          RBENV_VERSION
          CHRUBY_VERSION
          GEM_HOME
          GEM_PATH
          BUNDLE_PATH
          PATH
          SHELL
          HOMEBREW_CASK_OPTS
        ]

        locale_variables = ENV.keys.grep(/^(?:LC_\S+|LANG|LANGUAGE)\Z/).sort

        (locale_variables + environment_variables).sort.each(&method(:render_env_var))
      end

      def check_quarantine_support
        ohai "Gatekeeper support"

        case Quarantine.check_quarantine_support
        when :quarantine_available
          puts "Enabled"
        when :xattr_broken
          add_error "There's not a working version of xattr."
        when :no_swift
          add_error "Swift is not available on this system."
        when :no_quarantine
          add_error "This feature requires the macOS 10.10 SDK or higher."
        else
          onoe "Unknown support status"
        end
      end

      def user_tilde(path)
        self.class.user_tilde(path)
      end

      def cask_count_for_tap(tap)
        self.class.cask_count_for_tap(tap)
      end

      def none_string
        self.class.none_string
      end

      def render_env_var(var)
        self.class.render_env_var(var)
      end

      def self.check_sip
        csrutil = "/usr/bin/csrutil"
        return "N/A" unless File.executable?(csrutil)

        Open3.capture2(csrutil, "status")
             .first
             .gsub("This is an unsupported configuration, likely to break in " \
                   "the future and leave your machine in an unknown state.", "")
             .gsub("System Integrity Protection status: ", "")
             .delete("\t\.")
             .capitalize
             .strip
      end

      def self.locale_variables
        ENV.keys.grep(/^(?:LC_\S+|LANG|LANGUAGE)\Z/).sort
      end

      def self.none_string
        "<NONE>"
      end

      def self.error_string(string = "Error")
        Formatter.error("(#{string})")
      end

      def self.alt_taps
        Tap.select { |t| t.cask_dir.exist? && t != Tap.default_cask_tap }
      end

      def self.cask_count_for_tap(tap)
        Formatter.pluralize(tap.cask_files.count, "cask")
      rescue
        add_error "Unable to read from Tap: #{tap.path}"
        "0"
      end

      def self.render_env_var(var)
        return unless ENV.key?(var)

        var = %Q(#{var}="#{ENV[var]}")
        puts user_tilde(var)
      end

      def self.user_tilde(path)
        path.gsub(ENV["HOME"], "~")
      end

      def self.help
        "checks for configuration issues"
      end
    end
  end
end
