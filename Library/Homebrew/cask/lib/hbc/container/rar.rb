require "hbc/container/generic_unar"

module Hbc
  class Container
    class Rar
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\ARar!/n)
      end

      def extract
        path = @path
        unpack_dir = @cask.staged_path
        @command.run!(Formula["unrar"].opt_bin/"unrar", args: ["x", "-inul", path, unpack_dir])
      end

      def dependencies
        @dependencies ||= [Formula["unrar"]]
      end
    end
  end
end
