require "hbc/artifact/symlinked"

module Hbc
  module Artifact
    class Binary < Symlinked
      def install_phase
        super unless Hbc.no_binaries
      end
    end
  end
end
