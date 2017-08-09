require "hbc/container/naked"
require "vendor/macho/macho"

module Hbc
  class Container
    class Executable < Naked
      def self.me?(criteria)
        return true if criteria.magic_number(/^#!\s*\S+/)

        begin
          MachO.open(criteria.path).header.executable?
        rescue MachO::MagicError
          false
        end
      end
    end
  end
end
