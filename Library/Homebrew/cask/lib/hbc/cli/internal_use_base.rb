module Hbc
  class CLI
    class InternalUseBase < Base
      def self.command_name
        super.sub(%r{^internal_}i, "_")
      end

      def self.visible
        false
      end
    end
  end
end
