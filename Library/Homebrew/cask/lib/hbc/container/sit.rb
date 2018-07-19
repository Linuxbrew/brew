require "hbc/container/generic_unar"

module Hbc
  class Container
    class Sit < GenericUnar
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\AStuffIt/n)
      end
    end
  end
end
