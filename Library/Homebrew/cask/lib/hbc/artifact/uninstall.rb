require "hbc/artifact/abstract_uninstall"

module Hbc
  module Artifact
    class Uninstall < AbstractUninstall
      def uninstall_phase(**options)
        dispatch_uninstall_directives(**options)
      end
    end
  end
end
