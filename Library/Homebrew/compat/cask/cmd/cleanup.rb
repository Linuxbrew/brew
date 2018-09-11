require "cask/cmd/abstract_command"
require "cleanup"

using CleanupRefinement

module Cask
  class Cmd
    class Cleanup < AbstractCommand
      OUTDATED_DAYS = 10
      OUTDATED_TIMESTAMP = Time.now - (60 * 60 * 24 * OUTDATED_DAYS)

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
        odeprecated "`brew cask cleanup`", "`brew cleanup`", disable_on: Time.new(2018, 9, 30)

        cleanup = Homebrew::Cleanup.new

        casks(alternative: -> { Cask.to_a }).each do |cask|
          cleanup.cleanup_cask(cask)
        end

        return if cleanup.disk_cleanup_size.zero?

        disk_space = disk_usage_readable(cleanup.disk_cleanup_size)
        ohai "This operation has freed approximately #{disk_space} of disk space."
      end
    end
  end
end
