module Hbc
  class CLI
    class Reinstall < Install
      def install_casks
        casks.each do |cask|
          Installer.new(cask, binaries:       binaries?,
                              verbose:        verbose?,
                              force:          force?,
                              skip_cask_deps: skip_cask_deps?,
                              require_sha:    require_sha?).reinstall
        end
      end

      def self.help
        "reinstalls the given Cask"
      end
    end
  end
end
