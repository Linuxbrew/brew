module Cask
  class DSL
    class ConflictsWith
      VALID_KEYS = Set.new [
        :formula,
        :cask,
        :macos,
        :arch,
        :x11,
        :java,
      ]

      attr_reader *VALID_KEYS

      def initialize(pairs = {})
        @pairs = pairs

        VALID_KEYS.each do |key|
          instance_variable_set("@#{key}", Set.new)
        end

        pairs.each do |key, value|
          raise "invalid conflicts_with key: '#{key.inspect}'" unless VALID_KEYS.include?(key)

          instance_variable_set("@#{key}", instance_variable_get("@#{key}").merge([*value]))
        end
      end
    end
  end
end
