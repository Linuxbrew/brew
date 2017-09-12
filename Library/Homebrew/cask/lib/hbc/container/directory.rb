require "hbc/container/base"

module Hbc
  class Container
    class Directory < Base
      def self.me?(*)
        false
      end

      def extract
        @path.children.each do |child|
          next if skip_path?(child)
          FileUtils.cp child, @cask.staged_path
        end
      end

      private

      def skip_path?(*)
        false
      end
    end
  end
end
