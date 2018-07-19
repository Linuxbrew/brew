require "hbc/container/naked"
require "vendor/macho/macho"

module Hbc
  class Container
    class Executable < Naked
      def self.can_extract?(path:, magic_number:)
        return true if magic_number.match?(/\A#!\s*\S+/n)

        begin
          path.file? && MachO.open(path).header.executable?
        rescue MachO::MagicError
          false
        end
      end
    end
  end
end
