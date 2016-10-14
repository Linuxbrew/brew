require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Tar < Base
      def self.me?(criteria)
        criteria.magic_number(/^.{257}ustar/n) ||
          # or compressed tar (bzip2/gzip/lzma/xz)
          IO.popen(["/usr/bin/tar", "-t", "-f", criteria.path.to_s], err: "/dev/null") { |io| !io.read(1).nil? }
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/tar", args: ["-x", "-f", @path, "-C", unpack_dir])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
