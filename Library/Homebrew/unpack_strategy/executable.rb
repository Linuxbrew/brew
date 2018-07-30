require_relative "uncompressed"

module UnpackStrategy
  class Executable < Uncompressed
    using Magic

    def self.extensions
      [".sh", ".bash"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A#!\s*\S+/n) ||
        path.magic_number.match?(/\AMZ/n)
    end
  end
end
