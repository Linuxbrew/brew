require "hbc/container/base"

module Hbc
  class Container
    class Tar < Base
      def self.can_extract?(path:, magic_number:)
        return true if magic_number.match?(/\A.{257}ustar/n)

        # Check if `tar` can list the contents, then it can also extract it.
        IO.popen(["tar", "tf", path], err: File::NULL) do |stdout|
          !stdout.read(1).nil?
        end
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        system_command!("tar", args: ["xf", path, "-C", unpack_dir])
      end
    end
  end
end
