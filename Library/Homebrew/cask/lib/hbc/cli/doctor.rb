module Hbc
  class CLI
    class Doctor < AbstractCommand
      def initialize(*)
        super
        return if args.empty?
        raise ArgumentError, "#{self.class.command_name} does not take arguments."
      end

      def run
        ohai "Homebrew-Cask Version", Hbc.full_version
        ohai "Homebrew-Cask Install Location", self.class.render_install_location
        ohai "Homebrew-Cask Staging Location", self.class.render_staging_location(Hbc.caskroom)
        ohai "Homebrew-Cask Cached Downloads", self.class.render_cached_downloads
        ohai "Homebrew-Cask Taps:"
        puts self.class.render_taps(Hbc.default_tap, *self.class.alt_taps)
        ohai "Contents of $LOAD_PATH", self.class.render_load_path($LOAD_PATH)
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

        (self.class.locale_variables + environment_variables).sort.each(&self.class.method(:render_env_var))
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
        "0 #{error_string "error reading #{tap.path}"}"
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
