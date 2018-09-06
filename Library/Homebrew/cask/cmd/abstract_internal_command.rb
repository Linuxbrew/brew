module Cask
  class Cmd
    class AbstractInternalCommand < AbstractCommand
      def self.command_name
        super.sub(/^internal_/i, "_")
      end

      def self.visible
        false
      end
    end
  end
end
