require "hbc/container/base"

module Hbc
  class Container
    class Xz < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A\xFD7zXZ\x00/n)
      end

      def extract
        unpack_dir = @cask.staged_path
        basename = path.basename

        @command.run!("/usr/bin/ditto", args: ["--", path, unpack_dir])
        @command.run!("xz",
                      args: ["-q", "--", unpack_dir/basename],
                      env: { "PATH" => PATH.new(Formula["xz"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["xz"]]
      end
    end
  end
end
