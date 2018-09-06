require "cask/artifact/abstract_uninstall"

module Cask
  module Artifact
    class Uninstall < AbstractUninstall
      def uninstall_phase(**options)
        dispatch_uninstall_directives(**options)
      end
    end
  end
end
