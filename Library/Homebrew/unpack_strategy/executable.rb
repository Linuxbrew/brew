require_relative "uncompressed"

require "vendor/macho/macho"

module UnpackStrategy
  class Executable < Uncompressed
    def self.can_extract?(path:, magic_number:)
      return true if magic_number.match?(/\A#!\s*\S+/n)

      begin
        path.file? && MachO.open(path).header.executable?
      rescue MachO::NotAMachOError
        false
      end
    end
  end
end
