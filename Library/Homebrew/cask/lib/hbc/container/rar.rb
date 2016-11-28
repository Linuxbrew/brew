require "hbc/container/generic_unar"

module Hbc
  class Container
    class Rar < GenericUnar
      def self.me?(criteria)
        criteria.magic_number(/^Rar!/n) &&
          super
      end
    end
  end
end
