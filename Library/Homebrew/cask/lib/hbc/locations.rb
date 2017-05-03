require "tap"

module Hbc
  module Locations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_writer :caskroom

      def caskroom
        @caskroom ||= HOMEBREW_PREFIX.join("Caskroom")
      end

      attr_writer :cache

      def cache
        @cache ||= HOMEBREW_CACHE.join("Cask")
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

      attr_writer :dictionarydir

      def dictionarydir
        @dictionarydir ||= Pathname.new("~/Library/Dictionaries").expand_path
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
        @binarydir ||= HOMEBREW_PREFIX.join("bin")
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

      def tcc_db
        @tcc_db ||= Pathname.new("/Library/Application Support/com.apple.TCC/TCC.db")
      end

      def pre_mavericks_accessibility_dotfile
        @pre_mavericks_accessibility_dotfile ||= Pathname.new("/private/var/db/.AccessibilityAPIEnabled")
      end
    end
  end
end
