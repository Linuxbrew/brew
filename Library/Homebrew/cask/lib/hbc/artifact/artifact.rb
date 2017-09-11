require "hbc/artifact/moved"

require "hbc/utils/hash_validator"

module Hbc
  module Artifact
    class Artifact < Moved
      def self.english_name
        "Generic Artifact"
      end

      def self.from_args(cask, *args)
        source_string, target_hash = args

        if source_string.nil?
          raise CaskInvalidError.new(cask.token, "no source given for #{english_name}")
        end

        unless target_hash.is_a?(Hash)
          raise CaskInvalidError.new(cask.token, "target required for #{english_name} '#{source_string}'")
        end

        target_hash.extend(HashValidator).assert_valid_keys(:target)

        new(cask, source_string, **target_hash)
      end

      def self.resolve_target(target)
        Pathname(target)
      end

      def initialize(cask, source, target: nil)
        super(cask, source, target: target)
      end
    end
  end
end
