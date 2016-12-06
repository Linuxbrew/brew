require "hbc/source/tapped"

module Hbc
  module Source
    class TappedQualified < Tapped
      def self.me?(query)
        return if (tap = tap_for_query(query)).nil?

        tap.installed? && Hbc.path(query).exist?
      end

      def self.tap_for_query(query)
        qualified_token = QualifiedToken.parse(query)
        return if qualified_token.nil?

        user, repo = qualified_token[0..1]
        Tap.fetch(user, repo)
      end
    end
  end
end
