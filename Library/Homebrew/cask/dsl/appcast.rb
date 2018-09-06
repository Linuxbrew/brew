module Cask
  class DSL
    class Appcast
      attr_reader :uri, :checkpoint, :parameters

      def initialize(uri, **parameters)
        @uri        = URI(uri)
        @parameters = parameters
        @checkpoint = parameters[:checkpoint]
      end

      def to_yaml
        [uri, parameters].to_yaml
      end

      def to_s
        uri.to_s
      end
    end
  end
end
