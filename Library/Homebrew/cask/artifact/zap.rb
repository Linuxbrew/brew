require "cask/artifact/abstract_uninstall"

module Cask
  module Artifact
    class Zap < AbstractUninstall
      def zap_phase(**options)
        dispatch_uninstall_directives(**options)
      end
    end
  end
end
