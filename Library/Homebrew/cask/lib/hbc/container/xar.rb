require "hbc/container/base"

module Hbc
  class Container
    class Xar < Base
      def self.me?(criteria)
        criteria.magic_number(/\Axar!/n)
      end

      def extract
        unpack_dir = @cask.staged_path

        @command.run!("xar", args: ["-x", "-f", @path, "-C", unpack_dir])
      end
    end
  end
end
