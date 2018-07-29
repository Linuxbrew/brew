require_relative "uncompressed"

module UnpackStrategy
  class Otf < Uncompressed
    using Magic

    def self.can_extract?(path)
      path.magic_number.match?(/\AOTTO/n)
    end
  end
end
