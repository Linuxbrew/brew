require "hbc/artifact/abstract_uninstall"

module Hbc
  module Artifact
    class Zap < AbstractUninstall
      def zap_phase(**options)
        dispatch_uninstall_directives(**options)
      end
    end
  end
end
