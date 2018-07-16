require "hbc/container/base"

module Hbc
  class Container
    class Naked < Base
      def self.can_extract?(path:, magic_number:)
        false
      end

      def extract_to_dir(unpack_dir, basename:)
        @command.run!("/usr/bin/ditto", args: ["--", path, unpack_dir/basename])
      end
    end
  end
end
