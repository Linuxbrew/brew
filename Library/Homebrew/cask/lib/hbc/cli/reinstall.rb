module Hbc
  class CLI
    class Reinstall < Install
      def install_casks
        count = 0
        args.each do |cask_token|
          begin
            cask = CaskLoader.load(cask_token)

            Installer.new(cask,
                          binaries:       binaries?,
                          verbose: verbose?,
                          force:          force?,
                          skip_cask_deps: skip_cask_deps?,
                          require_sha:    require_sha?).reinstall

            count += 1
          rescue CaskUnavailableError => e
            self.class.warn_unavailable_with_suggestion cask_token, e
          rescue CaskError => e
            onoe e.message
          end
        end

        count.zero? ? nil : count == args.length
      end

      def self.help
        "reinstalls the given Cask"
      end
    end
  end
end
