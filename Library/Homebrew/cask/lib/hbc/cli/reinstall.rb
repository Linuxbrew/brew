module Hbc
  class CLI
    class Reinstall < Install
      def self.install_casks(cask_tokens, force, skip_cask_deps, require_sha)
        count = 0
        cask_tokens.each do |cask_token|
          begin
            cask = CaskLoader.load(cask_token)

            installer = Installer.new(cask,
                                      force:          force,
                                      skip_cask_deps: skip_cask_deps,
                                      require_sha:    require_sha)
            installer.print_caveats
            installer.fetch

            if cask.installed?
              # use copy of cask for uninstallation to avoid 'No such file or directory' bug
              installed_cask = cask

              # use the same cask file that was used for installation, if possible
              if (installed_caskfile = installed_cask.installed_caskfile).exist?
                installed_cask = CaskLoader.load_from_file(installed_caskfile)
              end

              # Always force uninstallation, ignore method parameter
              Installer.new(installed_cask, force: true).uninstall
            end

            installer.stage
            installer.install_artifacts
            installer.enable_accessibility_access
            puts installer.summary

            count += 1
          rescue CaskUnavailableError => e
            warn_unavailable_with_suggestion cask_token, e
          rescue CaskNoShasumError => e
            opoo e.message
            count += 1
          end
        end
        count.zero? ? nil : count == cask_tokens.length
      end

      def self.help
        "reinstalls the given Cask"
      end
    end
  end
end
