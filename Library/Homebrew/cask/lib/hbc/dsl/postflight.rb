require "hbc/staged"

module Hbc
  class DSL
    class Postflight < Base
      include Staged

      def suppress_move_to_applications(options = {})
        # TODO: Remove from all casks because it is no longer needed
      end
    end
  end
end
