require "hbc/container/base"

module Hbc
  class Container
    class Zip < Base
      def self.me?(criteria)
        criteria.magic_number(/^PK(\003\004|\005\006)/n)
      end

      def extract
        Dir.mktmpdir do |unpack_dir|
          @command.run!("/usr/bin/ditto", args: ["-x", "-k", "--", @path, unpack_dir])

          extract_nested_inside(unpack_dir)
        end
      end
    end
  end
end
