require_relative "tar"

module UnpackStrategy
  class Compress < Tar
    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A\037\235/n)
    end
  end
end
