module Hbc
  class CLI
    class Upgrade < AbstractCommand
      option "--greedy", :greedy, false
      option "--quiet",  :quiet, false
      option "--force", :force, false
      option "--force-update", :force_update, false
      option "--skip-cask-deps", :skip_cask_deps, false

      def initialize(*)
        super
        self.verbose = ($stdout.tty? || verbose?) && !quiet?
      end

      def run
        outdated_casks = casks(alternative: -> { Hbc.installed }).find_all { |cask| cask.outdated?(greedy?) }

        if outdated_casks.empty?
          oh1 "No packages to upgrade"
        else
          oh1 "Upgrading #{Formatter.pluralize(outdated_casks.length, "outdated package")}, with result:"
          puts outdated_casks.map { |f| "#{f.full_name} #{f.version}" } * ", "
        end

        outdated_casks.each do |old_cask|
          odebug "Uninstalling Cask #{old_cask}"

          raise CaskNotInstalledError, old_cask unless old_cask.installed? || force?

          unless old_cask.installed_caskfile.nil?
            # use the same cask file that was used for installation, if possible
            old_cask = CaskLoader.load(old_cask.installed_caskfile) if old_cask.installed_caskfile.exist?
          end

          old_cask_installer = Installer.new(old_cask, binaries: binaries?, verbose: verbose?, force: force?, upgrade: true)

          old_cask_installer.uninstall

          begin
            odebug "Installing new version of Cask #{old_cask}"

            new_cask = CaskLoader.load(old_cask.to_s)

            Installer.new(new_cask, binaries:       binaries?,
                                    verbose:        verbose?,
                                    force:          force?,
                                    skip_cask_deps: skip_cask_deps?,
                                    require_sha:    require_sha?,
                                    upgrade: true).install

            old_cask_installer.finalize_upgrade
          rescue CaskUnavailableError => e
            opoo e.message
          rescue CaskAlreadyInstalledError => e
            opoo e.message
          end
        end
      end

      def self.help
        "upgrades all outdated casks"
      end
    end
  end
end
