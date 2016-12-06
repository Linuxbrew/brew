module Hbc
  class CLI
    class Doctor < Base
      def self.run
        ohai "macOS Release:", render_with_none_as_error(MacOS.full_version)
        ohai "Hardware Architecture:", render_with_none_as_error("#{Hardware::CPU.type}-#{Hardware::CPU.bits}")
        ohai "Ruby Version:", render_with_none_as_error("#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}")
        ohai "Ruby Path:", render_with_none_as_error(RbConfig.ruby)
        # TODO: consider removing most Homebrew constants from doctor output
        ohai "Homebrew Version:", render_with_none_as_error(homebrew_version)
        ohai "Homebrew Executable Path:", render_with_none_as_error(HOMEBREW_BREW_FILE)
        ohai "Homebrew Cellar Path:", render_with_none_as_error(homebrew_cellar)
        ohai "Homebrew Repository Path:", render_with_none_as_error(HOMEBREW_REPOSITORY)
        ohai "Homebrew Origin:", render_with_none_as_error(homebrew_origin)
        ohai "Homebrew-Cask Version:", render_with_none_as_error(Hbc.full_version)
        ohai "Homebrew-Cask Install Location:", render_install_location
        ohai "Homebrew-Cask Staging Location:", render_staging_location(Hbc.caskroom)
        ohai "Homebrew-Cask Cached Downloads:", render_cached_downloads
        ohai "Homebrew-Cask Default Tap Path:", render_tap_paths(Hbc.default_tap.path)
        ohai "Homebrew-Cask Alternate Cask Taps:", render_tap_paths(alt_taps)
        ohai "Homebrew-Cask Default Tap Cask Count:", render_with_none_as_error(default_cask_count)
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

      def self.alt_taps
        Tap.select { |t| t.cask_dir && t != Hbc.default_tap }
           .map(&:path)
      end

      def self.default_cask_count
        Hbc.default_tap.cask_files.count
      rescue StandardError
        "0 #{error_string "Error reading #{Hbc.default_tap.path}"}"
      end

      def self.homebrew_origin
        homebrew_origin = notfound_string
        begin
          Dir.chdir(HOMEBREW_REPOSITORY) do
            homebrew_origin = SystemCommand.run("/usr/bin/git",
                                                     args:         %w[config --get remote.origin.url],
                                                     print_stderr: false).stdout.strip
          end
          if homebrew_origin !~ /\S/
            homebrew_origin = "#{none_string} #{error_string}"
          elsif homebrew_origin !~ %r{(mxcl|Homebrew)/(home)?brew(\.git)?\Z}
            homebrew_origin.concat " #{error_string "warning: nonstandard origin"}"
          end
        rescue StandardError
          homebrew_origin = error_string "Not Found - Error running git"
        end
        homebrew_origin
      end

      def self.homebrew_cellar
        homebrew_constants("cellar")
      end

      def self.homebrew_version
        homebrew_constants("version")
      end

      def self.homebrew_taps
        Tap::TAP_DIRECTORY
      end

      def self.homebrew_constants(name)
        @homebrew_constants ||= {}
        return @homebrew_constants[name] if @homebrew_constants.key?(name)
        @homebrew_constants[name] = notfound_string
        begin
          @homebrew_constants[name] = SystemCommand.run!(HOMEBREW_BREW_FILE,
                                                         args:         ["--#{name}"],
                                                         print_stderr: false)
                                                   .stdout
                                                   .strip
          if @homebrew_constants[name] !~ /\S/
            @homebrew_constants[name] = "#{none_string} #{error_string}"
          end
          path = Pathname.new(@homebrew_constants[name])
          @homebrew_constants[name] = path if path.exist?
        rescue StandardError
          @homebrew_constants[name] = error_string "Not Found - Error running brew"
        end
        @homebrew_constants[name]
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

      def self.notfound_string
        Formatter.error("Not Found - Unknown Error")
      end

      def self.error_string(string = "Error")
        Formatter.error("(#{string})")
      end

      def self.render_with_none(string)
        return string if !string.nil? && string.respond_to?(:to_s) && !string.to_s.empty?
        none_string
      end

      def self.render_with_none_as_error(string)
        return string if !string.nil? && string.respond_to?(:to_s) && !string.to_s.empty?
        "#{none_string} #{error_string}"
      end

      def self.render_tap_paths(paths)
        paths = [paths] unless paths.respond_to?(:each)
        paths.collect do |dir|
          if dir.nil? || dir.to_s.empty?
            none_string
          elsif dir.to_s.match(legacy_tap_pattern)
            dir.to_s.concat(" #{error_string "Warning: legacy tap path"}")
          else
            dir.to_s
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
        locations = Dir.glob(Pathname.new(homebrew_cellar).join("brew-cask", "*")).reverse
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
