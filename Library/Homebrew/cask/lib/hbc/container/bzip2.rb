require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Bzip2 < Base
      def self.me?(criteria)
        criteria.magic_number(/^BZh/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto",   args: ["--", @path, unpack_dir])
          @command.run!("/usr/bin/bunzip2", args: ["--quiet", "--", Pathname.new(unpack_dir).join(@path.basename)])

          extract_nested_inside(unpack_dir)
        end
      end
    end
  end
end
