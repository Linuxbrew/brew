require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Lzma < Base
      def self.me?(criteria)
        criteria.magic_number(/^\]\000\000\200\000/n)
      end

      def extract
        unless unlzma = which("unlzma", PATH.new(ENV["PATH"], HOMEBREW_PREFIX/"bin"))
          raise CaskError, "Expected to find unlzma executable. Cask '#{@cask}' must add: depends_on formula: 'lzma'"
        end

        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto", args: ["--", @path, unpack_dir])
          @command.run!(unlzma, args: ["-q", "--", Pathname(unpack_dir).join(@path.basename)])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
