require_relative "generic_unar"

module UnpackStrategy
  class SelfExtractingExecutable < GenericUnar
    using Magic

    def self.can_extract?(path)
      return false unless path.magic_number.match?(/\AMZ/n)

      path.file_type.include?("self-extracting archive")
    end
  end
end
