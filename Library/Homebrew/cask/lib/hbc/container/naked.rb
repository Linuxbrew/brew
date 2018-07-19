require "hbc/container/base"

module Hbc
  class Container
    class Naked < Base
      def self.can_extract?(path:, magic_number:)
        false
      end

      def extract
        @command.run!("/usr/bin/ditto", args: ["--", @path, @cask.staged_path.join(target_file)])
      end

      def target_file
        return @path.basename if @nested
        CGI.unescape(File.basename(@cask.url.path))
      end
    end
  end
end
