
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
        @default_tap ||= Tap.fetch("homebrew", "homebrew-cask")
      end
    end
  end
end
