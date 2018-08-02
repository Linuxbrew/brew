require_relative "uncompressed"

module UnpackStrategy
  class Pkg < Uncompressed
    using Magic

    def self.extensions
      [".pkg", ".mkpg"]
    end

    def self.can_extract?(path)
      path.extname.match?(/\A.m?pkg\Z/) &&
        (path.directory? || path.magic_number.match?(/\Axar!/n))
    end
  end
end
