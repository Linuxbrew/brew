module Hbc
  module Source
    class Gone
      def self.me?(query)
        WithoutSource.new(query).installed?
      end

      attr_reader :query

      def initialize(query)
        @query = query
      end

      def load
        WithoutSource.new(query)
      end

      def to_s
        ""
      end
    end
  end
end
