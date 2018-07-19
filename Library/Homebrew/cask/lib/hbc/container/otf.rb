require "hbc/container/naked"

module Hbc
  class Container
    class Otf < Naked
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\AOTTO/n)
      end
    end
  end
end
