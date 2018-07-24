require_relative "generic_unar"

module UnpackStrategy
  class SelfExtractingExecutable < GenericUnar
    def self.can_extract?(path:, magic_number:)
      return false unless magic_number.match?(/\AMZ/n)

      system_command("file",
                     args: [path],
                     print_stderr: false).stdout.include?("self-extracting")
    end
  end
end
