require "hbc/container/base"

module Hbc
  class Container
    class SevenZip < Base
      def self.can_extract?(path:, magic_number:)
        magic_number.match?(/\A7z\xBC\xAF\x27\x1C/n)
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        @command.run!("7zr",
                      args: ["x", "-y", "-bd", "-bso0", path, "-o#{unpack_dir}"],
                      env: { "PATH" => PATH.new(Formula["p7zip"].opt_bin, ENV["PATH"]) })
      end

      def dependencies
        @dependencies ||= [Formula["p7zip"]]
      end
    end
  end
end
