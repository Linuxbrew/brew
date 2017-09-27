require "hbc/artifact/moved"

module Hbc
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
