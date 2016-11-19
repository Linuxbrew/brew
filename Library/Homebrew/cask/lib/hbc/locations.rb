module Hbc
  module Locations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def legacy_caskroom
        @legacy_caskroom ||= Pathname.new("/opt/homebrew-cask/Caskroom")
      end

      def default_caskroom
        @default_caskroom ||= homebrew_prefix.join("Caskroom")
      end

      def caskroom
        @caskroom ||= begin
          if Utils.path_occupied?(legacy_caskroom)
            opoo <<-EOS.undent
              The default Caskroom location has moved to #{default_caskroom}.

              Please migrate your Casks to the new location and delete #{legacy_caskroom},
              or if you would like to keep your Caskroom at #{legacy_caskroom}, add the
              following to your HOMEBREW_CASK_OPTS:

                --caskroom=#{legacy_caskroom}

              For more details on each of those options, see https://github.com/caskroom/homebrew-cask/issues/21913.
            EOS
            legacy_caskroom
          else
            default_caskroom
          end
        end
      end

      def caskroom=(caskroom)
        @caskroom = caskroom
      end

      def legacy_cache
        @legacy_cache ||= homebrew_cache.join("Casks")
      end

      def cache
        @cache ||= homebrew_cache.join("Cask")
      end

      attr_writer :appdir

      def appdir
        @appdir ||= Pathname.new("/Applications").expand_path
      end

      attr_writer :prefpanedir

      def prefpanedir
        @prefpanedir ||= Pathname.new("~/Library/PreferencePanes").expand_path
      end

      attr_writer :qlplugindir

      def qlplugindir
        @qlplugindir ||= Pathname.new("~/Library/QuickLook").expand_path
      end

      attr_writer :fontdir

      def fontdir
        @fontdir ||= Pathname.new("~/Library/Fonts").expand_path
      end

      attr_writer :colorpickerdir

      def colorpickerdir
        @colorpickerdir ||= Pathname.new("~/Library/ColorPickers").expand_path
      end

      attr_writer :servicedir

      def servicedir
        @servicedir ||= Pathname.new("~/Library/Services").expand_path
      end

      attr_writer :binarydir

      def binarydir
        @binarydir ||= homebrew_prefix.join("bin")
      end

      attr_writer :input_methoddir

      def input_methoddir
        @input_methoddir ||= Pathname.new("~/Library/Input Methods").expand_path
      end

      attr_writer :internet_plugindir

      def internet_plugindir
        @internet_plugindir ||= Pathname.new("~/Library/Internet Plug-Ins").expand_path
      end

      attr_writer :audio_unit_plugindir

      def audio_unit_plugindir
        @audio_unit_plugindir ||= Pathname.new("~/Library/Audio/Plug-Ins/Components").expand_path
      end

      attr_writer :vst_plugindir

      def vst_plugindir
        @vst_plugindir ||= Pathname.new("~/Library/Audio/Plug-Ins/VST").expand_path
      end

      attr_writer :vst3_plugindir

      def vst3_plugindir
        @vst3_plugindir ||= Pathname.new("~/Library/Audio/Plug-Ins/VST3").expand_path
      end

      attr_writer :screen_saverdir

      def screen_saverdir
        @screen_saverdir ||= Pathname.new("~/Library/Screen Savers").expand_path
      end

      attr_writer :default_tap

      def default_tap
        @default_tap ||= Tap.fetch("caskroom", "homebrew-cask")
      end

      def path(query)
        query_path = Pathname.new(query)

        if query_path.exist? || query_path.absolute?
          return query_path
        end

        query_without_extension = query.sub(%r{\.rb$}i, "")

        token_with_tap = if query =~ %r{\A[^/]+/[^/]+/[^/]+\Z}
                           query_without_extension
                         else
                           all_tokens.detect { |tap_and_token|
                             tap_and_token.split("/")[2] == query_without_extension
                           }
                         end

        if token_with_tap
          user, repo, token = token_with_tap.split("/")
          tap = Tap.fetch(user, repo)
        else
          token = query_without_extension
          tap = Hbc.default_tap
        end

        return query_path if tap.cask_dir.nil?
        tap.cask_dir.join("#{token}.rb")
      end

      def tcc_db
        @tcc_db ||= Pathname.new("/Library/Application Support/com.apple.TCC/TCC.db")
      end

      def pre_mavericks_accessibility_dotfile
        @pre_mavericks_accessibility_dotfile ||= Pathname.new("/private/var/db/.AccessibilityAPIEnabled")
      end

      def x11_executable
        @x11_executable ||= Pathname.new("/usr/X11/bin/X")
      end

      def x11_libpng
        @x11_libpng ||= [Pathname.new("/opt/X11/lib/libpng.dylib"), Pathname.new("/usr/X11/lib/libpng.dylib")]
      end

      def homebrew_cache
        @homebrew_cache ||= HOMEBREW_CACHE
      end

      def homebrew_cache=(path)
        @homebrew_cache = path ? Pathname.new(path) : path
      end

      def homebrew_executable
        @homebrew_executable ||= HOMEBREW_BREW_FILE
      end

      def homebrew_prefix
        # where Homebrew links
        @homebrew_prefix ||= HOMEBREW_PREFIX
      end

      def homebrew_prefix=(path)
        @homebrew_prefix = path ? Pathname.new(path) : path
      end

      def homebrew_repository
        # where Homebrew's .git dir is found
        @homebrew_repository ||= HOMEBREW_REPOSITORY
      end

      def homebrew_repository=(path)
        @homebrew_repository = path ? Pathname.new(path) : path
      end
    end
  end
end
