require_relative "uncompressed"

module UnpackStrategy
  class Diff < Uncompressed
    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A---\040/n)
    end
  end
end
