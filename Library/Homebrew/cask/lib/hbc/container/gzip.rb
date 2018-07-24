require "hbc/container/base"

module Hbc
  class Container
    class Gzip < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A\037\213/n)
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        Dir.mktmpdir do |tmp_unpack_dir|
          tmp_unpack_dir = Pathname(tmp_unpack_dir)

          FileUtils.cp path, tmp_unpack_dir/basename, preserve: true
          system_command!("gunzip", args: ["--quiet", "--name", "--", tmp_unpack_dir/basename])

          extract_nested_inside(tmp_unpack_dir, to: unpack_dir)
        end
      end
    end
  end
end
