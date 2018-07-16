require "hbc/container/base"

module Hbc
  class Container
    class Zip < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\APK(\003\004|\005\006)/n)
      end

      def extract_to_dir(unpack_dir, basename:)
        Dir.mktmpdir do |tmp_unpack_dir|
          @command.run!("/usr/bin/ditto", args: ["-x", "-k", "--", path, tmp_unpack_dir])

          extract_nested_inside(tmp_unpack_dir, to: unpack_dir)
        end
      end
    end
  end
end
