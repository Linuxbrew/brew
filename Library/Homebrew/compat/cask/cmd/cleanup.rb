require "cask/cmd/abstract_command"
require "cleanup"

using CleanupRefinement

module Cask
  class Cmd
    class Cleanup < AbstractCommand
      def self.help
        "cleans up cached downloads and tracker symlinks"
      end

      def self.visible
        false
      end

      attr_reader :cache_location

      def initialize(*args, cache_location: Cache.path)
        super(*args)
        @cache_location = Pathname.new(cache_location)
      end

      def run
        odisabled "`brew cask cleanup`", "`brew cleanup`"
      end
    end
  end
end
