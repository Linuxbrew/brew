module Hbc
  class Container
    class SvnRepository < Base
      def self.can_extract?(path:, magic_number:)
        (path/".svn").directory?
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        system_command!("svn", args: ["export", "--force", path, unpack_dir])
      end
    end
  end
end
