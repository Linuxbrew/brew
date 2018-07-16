require "hbc/container/naked"

module Hbc
  class Container
    class Ttf < Naked
      def self.can_extract?(path:, magic_number:)
        # TrueType Font
        magic_number.match?(/\A\000\001\000\000\000/n) ||
          # Truetype Font Collection
          magic_number.match?(/\Attcf/n)
      end
    end
  end
end
