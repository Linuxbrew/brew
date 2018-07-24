require_relative "uncompressed"

module UnpackStrategy
  class Pkg < Uncompressed
    def self.can_extract?(path:, magic_number:)
      path.extname.match?(/\A.m?pkg\Z/) &&
        (path.directory? || magic_number.match?(/\Axar!/n))
    end
  end
end
