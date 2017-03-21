require "hbc/artifact/uninstall_base"

module Hbc
  module Artifact
    class Uninstall < UninstallBase
      def uninstall_phase
        dispatch_uninstall_directives
      end
    end
  end
end
