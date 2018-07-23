require "hbc/container/base"

module Hbc
  class Container
    class Lzma < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A\]\000\000\200\000/n)
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        system_command!("/usr/bin/ditto", args: ["--", path, unpack_dir])
        system_command!("unlzma",
                        args: ["-q", "--", Pathname(unpack_dir).join(basename)],
                        env: { "PATH" => PATH.new(Formula["unlzma"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["unlzma"]]
      end
    end
  end
end
