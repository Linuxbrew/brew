require "hbc/container/generic_unar"

module Hbc
  class Container
    class Sit < GenericUnar
      def self.me?(criteria)
        criteria.magic_number(/^StuffIt/n) &&
          super
      end
    end
  end
end
