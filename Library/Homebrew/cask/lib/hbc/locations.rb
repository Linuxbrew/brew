require "tap"

module Hbc
  module Locations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def caskroom
        @caskroom ||= HOMEBREW_PREFIX.join("Caskroom")
      end

      def cache
        @cache ||= HOMEBREW_CACHE.join("Cask")
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
