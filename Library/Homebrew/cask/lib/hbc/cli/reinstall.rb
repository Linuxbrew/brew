module Hbc
  class CLI
    class Reinstall < Install
      def self.install_casks(cask_tokens, force, skip_cask_deps, require_sha)
        count = 0
        cask_tokens.each do |cask_token|
          begin
            cask = Hbc.load(cask_token)

            installer = Installer.new(cask,
                                      force:          force,
                                      skip_cask_deps: skip_cask_deps,
                                      require_sha:    require_sha)
            installer.print_caveats

            # Download
            begin
              installer.satisfy_dependencies
              installer.verify_has_sha if @require_sha && !@force
              installer.download
              installer.verify
            rescue StandardError => e
              installer.purge_versioned_files
              raise e
            end

            # Uninstall
            if cask.installed?
              # use copy of cask for uninstallation to avoid 'No such file or directory' bug
              installed_cask = cask
              latest_installed_version = installed_cask.timestamped_versions.last

              unless latest_installed_version.nil?
                latest_installed_cask_file = installed_cask.metadata_master_container_path
                                                           .join(latest_installed_version
                                                           .join(File::Separator),
                                                           "Casks", "#{cask_token}.rb")

                # use the same cask file that was used for installation, if possible
                installed_cask = CaskLoader.load_from_file(latest_installed_cask_file) if latest_installed_cask_file.exist?
              end

              # Always force uninstallation, ignore method parameter
              Installer.new(installed_cask, force: true).uninstall
            end

            # Reinstall
            begin
              installer.extract_primary_container
              installer.install_artifacts
              installer.save_caskfile
              installer.enable_accessibility_access
            rescue StandardError => e
              installer.purge_versioned_files
              raise e
            end

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
