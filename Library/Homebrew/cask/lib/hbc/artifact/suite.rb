require "hbc/artifact/moved"

module Hbc
  module Artifact
    class Suite < Moved
      def self.artifact_english_name
        "App Suite"
      end

      def self.artifact_dirmethod
        :appdir
      end
    end
  end
end
