require "cask/artifact/moved"

module Cask
  module Artifact
    class Suite < Moved
      def self.english_name
        "App Suite"
      end

      def self.dirmethod
        :appdir
      end
    end
  end
end
