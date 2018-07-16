require "hbc/container/generic_unar"

module Hbc
  class Container
    class SelfExtractingExecutable < GenericUnar
      def self.can_extract?(path:, magic_number:)
        return false unless magic_number.match?(/\AMZ/n)

        SystemCommand.run("file",
                          args: [path],
                          print_stderr: false).stdout.include?("self-extracting")
      end
    end
  end
end
