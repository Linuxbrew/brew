require "hbc/container/base"

module Hbc
  class Container
    class Lzma < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A\]\000\000\200\000/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto", args: ["--", @path, unpack_dir])
          @command.run!("unlzma",
                        args: ["-q", "--", Pathname(unpack_dir).join(@path.basename)],
                        env: { "PATH" => PATH.new(Formula["unlzma"].opt_bin, ENV["PATH"]) })
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end

      def dependencies
        @dependencies ||= [Formula["unlzma"]]
      end
    end
  end
end
