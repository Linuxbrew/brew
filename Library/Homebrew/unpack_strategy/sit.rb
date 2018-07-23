require_relative "generic_unar"

module UnpackStrategy
  class Sit < GenericUnar
    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\AStuffIt/n)
    end
  end
end
