require "tmpdir"

require "hbc/container/base"

module Hbc
  class Container
    class GenericUnar < Base
      def self.me?(criteria)
        !(lsar = which("lsar")).nil? &&
          criteria.command.run(lsar,
                               args:         ["-l", "-t", "--", criteria.path],
                               print_stderr: false).stdout.chomp.end_with?("passed, 0 failed.")
      end

      def extract
        if (unar = which("unar")).nil?
          raise CaskError, "Expected to find unar executable. Cask #{@cask} must add: depends_on formula: 'unar'"
        end

        Dir.mktmpdir do |unpack_dir|
          @command.run!(unar, args: ["-force-overwrite", "-quiet", "-no-directory", "-output-directory", unpack_dir, "--", @path])
          @command.run!("/usr/bin/ditto", args: ["--", unpack_dir, @cask.staged_path])
        end
      end
    end
  end
end
