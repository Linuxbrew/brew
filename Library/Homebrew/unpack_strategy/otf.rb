require_relative "uncompressed"

module UnpackStrategy
  class Otf < Uncompressed
    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\AOTTO/n)
    end
  end
end
