require "hbc/container/generic_unar"

module Hbc
  class Container
    class SevenZip < GenericUnar
      def self.me?(criteria)
        # TODO: cover self-extracting archives
        criteria.magic_number(/^7z/n) &&
          super
      end
    end
  end
end
