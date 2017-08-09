require "hbc/container"

module Hbc
  class DSL
    class Container
      VALID_KEYS = Set.new [
        :type,
        :nested,
      ]

      attr_accessor(*VALID_KEYS)
      attr_accessor :pairs

      def initialize(pairs = {})
        @pairs = pairs
        pairs.each do |key, value|
          raise "invalid container key: '#{key.inspect}'" unless VALID_KEYS.include?(key)
          send(:"#{key}=", value)
        end

        return if type.nil?
        return unless Hbc::Container.from_type(type).nil?
        raise "invalid container type: #{type.inspect}"
      end

      def to_yaml
        @pairs.to_yaml
      end

      def to_s
        @pairs.inspect
      end
    end
  end
end
