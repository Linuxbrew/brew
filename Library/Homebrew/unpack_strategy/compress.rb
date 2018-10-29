require_relative "tar"

module UnpackStrategy
  class Compress < Tar
    using Magic

    def self.extensions
      [".Z"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A\037\235/n)
    end
  end
end
