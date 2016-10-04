module Hbc
  class DSL
    class Appcast
      attr_reader :parameters, :checkpoint

      def initialize(uri, parameters = {})
        @parameters     = parameters
        @uri            = UnderscoreSupportingURI.parse(uri)
        @checkpoint     = @parameters[:checkpoint]
      end

      def to_yaml
        [@uri, @parameters].to_yaml
      end

      def to_s
        @uri.to_s
      end
    end
  end
end
