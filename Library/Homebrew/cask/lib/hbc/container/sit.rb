require "hbc/container/generic_unar"

module Hbc
  class Container
    class Sit < GenericUnar
      def self.me?(criteria)
        criteria.magic_number(/\AStuffIt/n)
      end
    end
  end
end
