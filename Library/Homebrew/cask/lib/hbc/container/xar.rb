require "hbc/container/base"

module Hbc
  class Container
    class Xar < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\Axar!/n)
      end

      def extract
        unpack_dir = @cask.staged_path

        @command.run!("xar", args: ["-x", "-f", @path, "-C", unpack_dir])
      end
    end
  end
end
