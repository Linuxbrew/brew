module Hbc
  module Source
    class Tapped
      def self.me?(query)
        Hbc.path(query).exist?
      end

      attr_reader :token

      def initialize(token)
        @token = token
      end

      def load
        PathSlashOptional.new(Hbc.path(token)).load
      end

      def to_s
        # stringify to fully-resolved location
        Hbc.path(token).expand_path.to_s
      end
    end
  end
end
