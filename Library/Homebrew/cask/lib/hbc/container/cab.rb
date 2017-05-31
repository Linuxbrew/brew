require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class Cab < Base
      def self.me?(criteria)
        criteria.magic_number(/^(MSCF|MZ)/n)
      end

      def extract
        if (cabextract = which("cabextract")).nil?
          raise CaskError, "Expected to find cabextract executable. Cask '#{@cask}' must add: depends_on formula: 'cabextract'"
        end

        Dir.mktmpdir do |unpack_dir|
          @command.run!(cabextract, args: ["-d", unpack_dir, "--", @path])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
