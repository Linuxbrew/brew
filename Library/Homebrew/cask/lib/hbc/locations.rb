
module Hbc
  module Locations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_writer :default_tap

      def default_tap
        @default_tap ||= Tap.fetch("homebrew", "homebrew-cask")
      end
    end
  end
end
