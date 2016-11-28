require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Gzip < Base
      def self.me?(criteria)
        criteria.magic_number(/^\037\213/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto",  args: ["--", @path, unpack_dir])
          @command.run!("/usr/bin/gunzip", args: ["--quiet", "--name", "--", Pathname.new(unpack_dir).join(@path.basename)])

          extract_nested_inside(unpack_dir)
        end
      end
    end
  end
end
