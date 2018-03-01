require "system_config"
require "hbc/checkable"

module Hbc
  class CLI
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
        check_install_location
        check_staging_location
        check_cached_downloads
        check_taps
        check_load_path
        check_environment_variables

        puts summary unless success?
        raise CaskError, "There are some problems with your setup." unless success?
      end

      def check_software_versions
        ohai "Homebrew-Cask Version", Hbc.full_version
        ohai "macOS", MacOS.full_version
        ohai "SIP", self.class.check_sip
        ohai "Java", SystemConfig.describe_java
      end

      # This could be done by calling into Homebrew, but the situation
      # where "doctor" is needed is precisely the situation where such
      # things are less dependable.
      def check_install_location
        ohai "Homebrew-Cask Install Location"

        locations = Dir.glob(HOMEBREW_CELLAR.join("brew-cask", "*")).reverse
        if locations.empty?
          puts self.class.none_string
        else
          locations.collect do |l|
            add_error "Legacy install at #{l}. Run \"brew uninstall --force brew-cask\"."
            puts l
          end
        end
      end

      def check_staging_location
        ohai "Homebrew-Cask Staging Location"

        path = Pathname.new(user_tilde(Hbc.caskroom.to_s))

        if !path.exist?
          add_error "The staging path #{path} does not exist."
        elsif !path.writable?
          add_error "The staging path #{path} is not writable by the current user."
        end

        puts path
      end

      def check_cached_downloads
        ohai "Homebrew-Cask Cached Downloads"

        cleanup = CLI::Cleanup.new
        count = cleanup.cache_files.count
        size = cleanup.disk_cleanup_size
        msg = user_tilde(Hbc.cache.to_s)
        msg << " (#{number_readable(count)} files, #{disk_usage_readable(size)})" unless count.zero?
        puts msg
      end

      def check_taps
        ohai "Homebrew-Cask Taps:"

        default_tap = [Hbc.default_tap]

        alt_taps = Tap.select { |t| t.cask_dir.exist? && t != Hbc.default_tap }

        (default_tap + alt_taps).each do |tap|
          if tap.path.nil? || tap.path.to_s.empty?
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
        ]

        locale_variables = ENV.keys.grep(/^(?:LC_\S+|LANG|LANGUAGE)\Z/).sort

        (locale_variables + environment_variables).sort.each(&method(:render_env_var))
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
        Open3.capture2(csrutil, "status")[0]
             .gsub("This is an unsupported configuration, likely to break in the future and leave your machine in an unknown state.", "")
             .gsub("System Integrity Protection status: ", "")
             .delete("\t\.").capitalize.strip
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

      def self.render_with_none(string)
        return string if !string.nil? && string.respond_to?(:to_s) && !string.to_s.empty?
        none_string
      end

      def self.alt_taps
        Tap.select { |t| t.cask_dir.exist? && t != Hbc.default_tap }
      end

      def self.cask_count_for_tap(tap)
        Formatter.pluralize(tap.cask_files.count, "cask")
      rescue StandardError
        add_error "Unable to read from Tap: #{tap.path}"
        "0"
      end

      def self.render_taps(*taps)
        taps.collect do |tap|
          if tap.path.nil? || tap.path.to_s.empty?
            none_string
          else
            "#{tap.path} (#{cask_count_for_tap(tap)})"
          end
        end
      end

      def self.render_env_var(var)
        return unless ENV.key?(var)
        var = %Q(#{var}="#{ENV[var]}")
        puts user_tilde(var)
      end

      def self.user_tilde(path)
        path.gsub(ENV["HOME"], "~")
      end

      # This could be done by calling into Homebrew, but the situation
      # where "doctor" is needed is precisely the situation where such
      # things are less dependable.
      def self.render_install_location
        locations = Dir.glob(HOMEBREW_CELLAR.join("brew-cask", "*")).reverse
        if locations.empty?
          none_string
        else
          locations.collect do |l|
            "#{l} #{error_string 'error: legacy install. Run "brew uninstall --force brew-cask".'}"
          end
        end
      end

      def self.render_staging_location(path)
        path = Pathname.new(user_tilde(path.to_s))
        if !path.exist?
          "#{path} #{error_string "error: path does not exist"}"
        elsif !path.writable?
          "#{path} #{error_string "error: not writable by current user"}"
        else
          path
        end
      end

      def self.render_load_path(paths)
        paths.map(&method(:user_tilde))
        return "#{none_string} #{error_string}" if [*paths].empty?
        paths
      end

      def self.render_cached_downloads
        cleanup = CLI::Cleanup.new
        count = cleanup.cache_files.count
        size = cleanup.disk_cleanup_size
        msg = user_tilde(Hbc.cache.to_s)
        msg << " (#{number_readable(count)} files, #{disk_usage_readable(size)})" unless count.zero?
        msg
      end

      def self.help
        "checks for configuration issues"
      end
    end
  end
end
