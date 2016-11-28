module Hbc
  class DSL
    class StanzaProxy
      attr_reader :type

      def self.once(type)
        resolved = nil
        new(type) { resolved ||= yield }
      end

      def initialize(type, &resolver)
        @type = type
        @resolver = resolver
      end

      def proxy?
        true
      end

      def to_s
        @resolver.call.to_s
      end

      # Serialization for dumpcask
      def encode_with(coder)
        coder["type"] = type
        coder["resolved"] = @resolver.call
      end

      def method_missing(method, *args)
        if method != :to_ary
          @resolver.call.send(method, *args)
        else
          super
        end
      end

      def respond_to?(method, include_private = false)
        return true if [:encode_with, :proxy?, :to_s, :type].include?(method)
        return false if method == :to_ary
        @resolver.call.respond_to?(method, include_private)
      end

      def respond_to_missing?(*)
        true
      end
    end
  end
end
