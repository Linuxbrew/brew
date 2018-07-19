module Hbc
  class Container
    class SvnRepository < Base
      def self.can_extract?(path:, magic_number:)
        (path/".svn").directory?
      end

      def extract
        path = @path
        unpack_dir = @cask.staged_path

        @command.run!("svn", args: ["export", "--force", path, unpack_dir])
      end
    end
  end
end
