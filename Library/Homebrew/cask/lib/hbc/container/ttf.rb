require "hbc/container/naked"

module Hbc
  class Container
    class Ttf < Naked
      def self.me?(criteria)
        # TrueType Font
        criteria.magic_number(/^\000\001\000\000\000/n) ||
          # Truetype Font Collection
          criteria.magic_number(/^ttcf/n)
      end
    end
  end
end
