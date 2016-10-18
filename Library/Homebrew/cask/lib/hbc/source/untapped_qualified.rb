require "hbc/source/tapped_qualified"

module Hbc
  module Source
    class UntappedQualified < TappedQualified
      def self.me?(query)
        return if (tap = tap_for_query(query)).nil?

        tap.install
        tap.installed? && path_for_query(query).exist?
      end
    end
  end
end
