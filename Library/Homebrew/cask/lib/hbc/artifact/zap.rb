require "hbc/artifact/uninstall_base"

module Hbc
  module Artifact
    class Zap < UninstallBase
      def zap_phase
        dispatch_uninstall_directives
      end
    end
  end
end
