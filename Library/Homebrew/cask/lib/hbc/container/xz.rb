require "hbc/container/base"

module Hbc
  class Container
    class Xz < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A\xFD7zXZ\x00/n)
      end

      def extract_to_dir(unpack_dir, basename:)
        @command.run!("/usr/bin/ditto", args: ["--", path, unpack_dir])
        @command.run!("unxz",
                      args: ["-q", "--", unpack_dir/basename],
                      env: { "PATH" => PATH.new(Formula["xz"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["xz"]]
      end
    end
  end
end
