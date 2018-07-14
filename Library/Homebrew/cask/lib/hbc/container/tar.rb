require "hbc/container/base"

module Hbc
  class Container
    class Tar < Base
      def self.me?(criteria)
        criteria.magic_number(/\A.{257}ustar/n) ||
          # or compressed tar (bzip2/gzip/lzma/xz)
          IO.popen(["/usr/bin/tar", "-t", "-f", criteria.path.to_s], err: File::NULL) { |io| !io.read(1).nil? }
      end

      def extract
        unpack_dir = @cask.staged_path

        @command.run!("tar", args: ["xf", path, "-C", unpack_dir])
      end
    end
  end
end
