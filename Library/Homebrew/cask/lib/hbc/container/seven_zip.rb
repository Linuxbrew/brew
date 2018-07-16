require "hbc/container/generic_unar"

module Hbc
  class Container
    class SevenZip < GenericUnar
      def self.me?(criteria)
        criteria.magic_number(/\A7z\xBC\xAF\x27\x1C/n)
      end

      def extract
        unpack_dir = @cask.staged_path

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
