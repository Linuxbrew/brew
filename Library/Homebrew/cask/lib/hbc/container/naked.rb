require "hbc/container/base"

module Hbc
  class Container
    class Naked < Base
      # Either inherit from this class and override with self.me?(criteria),
      # or use this class directly as "container type: :naked",
      # in which case self.me? is not called.
      def self.me?(*)
        false
      end

      def extract
        @command.run!("/usr/bin/ditto", args: ["--", @path, @cask.staged_path.join(target_file)])
      end

      def target_file
        return @path.basename if @nested
        URI.decode(File.basename(@cask.url.path))
      end
    end
  end
end
