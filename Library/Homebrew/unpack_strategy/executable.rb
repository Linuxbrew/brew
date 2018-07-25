require_relative "uncompressed"

module UnpackStrategy
  class Executable < Uncompressed
    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A#!\s*\S+/n)
    end
  end
end
