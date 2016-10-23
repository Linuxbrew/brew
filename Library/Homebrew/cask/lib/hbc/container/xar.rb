require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Xar < Base
      def self.me?(criteria)
        criteria.magic_number(/^xar!/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/xar", args: ["-x", "-f", @path, "-C", unpack_dir])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
