require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Xz < Base
      def self.me?(criteria)
        criteria.magic_number(/^\xFD7zXZ\x00/n)
      end

      def extract
        if (unxz = which("unxz")).nil?
          raise CaskError, "Expected to find unxz executable. Cask '#{@cask}' must add: depends_on formula: 'xz'"
        end

        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto", args: ["--", @path, unpack_dir])
          @command.run!(unxz, args: ["-q", "--", Pathname(unpack_dir).join(@path.basename)])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
