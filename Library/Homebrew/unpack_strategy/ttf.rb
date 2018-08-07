require_relative "uncompressed"

module UnpackStrategy
  class Ttf < Uncompressed
    using Magic

    def self.extensions
      [".ttc", ".ttf"]
    end

    def self.can_extract?(path)
      # TrueType Font
      path.magic_number.match?(/\A\000\001\000\000\000/n) ||
        # Truetype Font Collection
        path.magic_number.match?(/\Attcf/n)
    end
  end
end
