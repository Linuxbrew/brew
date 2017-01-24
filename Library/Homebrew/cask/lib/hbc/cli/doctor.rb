module Hbc
  class CLI
    class Doctor < Base
      def self.run
        ohai "Homebrew-Cask Version:", Hbc.full_version
        ohai "Homebrew-Cask Install Location:", render_install_location
        ohai "Homebrew-Cask Staging Location:", render_staging_location(Hbc.caskroom)
        ohai "Homebrew-Cask Cached Downloads:", render_cached_downloads
        ohai "Homebrew-Cask Taps:"
        puts render_taps(Hbc.default_tap)
        puts render_taps(*alt_taps)
        ohai "Contents of $LOAD_PATH:", render_load_path($LOAD_PATH)
        ohai "Contents of $RUBYLIB Environment Variable:", render_env_var("RUBYLIB")
        ohai "Contents of $RUBYOPT Environment Variable:", render_env_var("RUBYOPT")
        ohai "Contents of $RUBYPATH Environment Variable:", render_env_var("RUBYPATH")
        ohai "Contents of $RBENV_VERSION Environment Variable:", render_env_var("RBENV_VERSION")
        ohai "Contents of $CHRUBY_VERSION Environment Variable:", render_env_var("CHRUBY_VERSION")
        ohai "Contents of $GEM_HOME Environment Variable:", render_env_var("GEM_HOME")
        ohai "Contents of $GEM_PATH Environment Variable:", render_env_var("GEM_PATH")
        ohai "Contents of $BUNDLE_PATH Environment Variable:", render_env_var("BUNDLE_PATH")
        ohai "Contents of $PATH Environment Variable:", render_env_var("PATH")
        ohai "Contents of $SHELL Environment Variable:", render_env_var("SHELL")
        ohai "Contents of Locale Environment Variables:", render_with_none(locale_variables)
      end

      def self.locale_variables
        ENV.keys.grep(/^(?:LC_\S+|LANG|LANGUAGE)\Z/).collect { |v| %Q(#{v}="#{ENV[v]}") }.sort.join("\n")
      end

      def self.none_string
        "<NONE>"
      end

      def self.legacy_tap_pattern
        /phinze/
      end

      def self.error_string(string = "Error")
        Formatter.error("(#{string})")
      end

      def self.render_with_none(string)
        return string if !string.nil? && string.respond_to?(:to_s) && !string.to_s.empty?
        none_string
      end

      def self.alt_taps
        Tap.select { |t| t.cask_dir && t != Hbc.default_tap }
      end

      def self.cask_count_for_tap(tap)
        count = tap.cask_files.count
        "#{count} #{count == 1 ? "cask" : "casks"}"
      rescue StandardError
        "0 #{error_string "error reading #{tap.path}"}"
      end

      def self.render_taps(*taps)
        taps.collect do |tap|
          if tap.path.nil? || tap.path.to_s.empty?
            none_string
          elsif tap.path.to_s.match(legacy_tap_pattern)
            tap.path.to_s.concat(" #{error_string "Warning: legacy tap path"}")
          else
            "#{tap.path} (#{cask_count_for_tap(tap)})"
          end
        end
      end

      def self.render_env_var(var)
        if ENV.key?(var)
          %Q(#{var}="#{ENV[var]}")
        else
          none_string
        end
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
        path = Pathname.new(path)
        if !path.exist?
          "#{path} #{error_string "error: path does not exist"}}"
        elsif !path.writable?
          "#{path} #{error_string "error: not writable by current user"}"
        else
          path
        end
      end

      def self.render_load_path(paths)
        return "#{none_string} #{error_string}" if [*paths].empty?
        paths
      end

      def self.render_cached_downloads
        cleanup = CLI::Cleanup.default
        files = cleanup.cache_files
        count = files.count
        size = cleanup.disk_cleanup_size
        size_msg = "#{number_readable(count)} files, #{disk_usage_readable(size)}"
        warn_msg = error_string('warning: run "brew cask cleanup"')
        size_msg << " #{warn_msg}" if count > 0
        [Hbc.cache, size_msg]
      end

      def self.help
        "checks for configuration issues"
      end
    end
  end
end
