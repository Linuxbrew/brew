module Cask
  class Cmd
    class Reinstall < Install
      def run
        casks.each do |cask|
          Installer.new(cask, binaries:       binaries?,
                              verbose:        verbose?,
                              force:          force?,
                              skip_cask_deps: skip_cask_deps?,
                              require_sha:    require_sha?,
                              quarantine:     quarantine?).reinstall
        end
      end

      def self.help
        "reinstalls the given Cask"
      end
    end
  end
end
