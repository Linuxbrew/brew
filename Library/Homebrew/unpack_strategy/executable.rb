require_relative "uncompressed"

module UnpackStrategy
  class Executable < Uncompressed
    using Magic

    def self.can_extract?(path)
      path.magic_number.match?(/\A#!\s*\S+/n)
    end
  end
end
