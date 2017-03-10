require "hbc/artifact/symlinked"

module Hbc
  module Artifact
    class Binary < Symlinked
      def install_phase
        super if CLI.binaries?
      end

      def link
        super
        FileUtils.chmod "+x", source
      end
    end
  end
end
