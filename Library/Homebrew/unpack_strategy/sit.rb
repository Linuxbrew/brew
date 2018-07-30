require_relative "generic_unar"

module UnpackStrategy
  class Sit < GenericUnar
    using Magic

    def self.extensions
      [".sit"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\AStuffIt/n)
    end
  end
end
