require "cask/artifact/abstract_artifact"

module Cask
  module Artifact
    class StageOnly < AbstractArtifact
      def self.from_args(cask, *args)
        if args != [true]
          raise CaskInvalidError.new(cask.token, "'stage_only' takes only a single argument: true")
        end

        new(cask)
      end

      def initialize(cask)
        super(cask)
      end

      def to_a
        [true]
      end
    end
  end
end
