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
        outdated_casks = casks(alternative: -> { Hbc.installed }).select { |cask| cask.outdated?(greedy?) }

        return if outdated_casks.empty?

        oh1 "Upgrading #{Formatter.pluralize(outdated_casks.length, "outdated package")}, with result:"
        puts outdated_casks.map { |f| "#{f.full_name} #{f.version}" } * ", "

        outdated_casks.each do |old_cask|
          odebug "Uninstalling Cask #{old_cask}"

          raise CaskNotInstalledError, old_cask unless old_cask.installed? || force?

          unless old_cask.installed_caskfile.nil?
            # use the same cask file that was used for installation, if possible
            old_cask = CaskLoader.load(old_cask.installed_caskfile) if old_cask.installed_caskfile.exist?
          end

          old_cask_installer = Installer.new(old_cask, binaries: binaries?, verbose: verbose?, force: force?, upgrade: true)

          new_cask = CaskLoader.load(old_cask.to_s)

          new_cask_installer =
            Installer.new(new_cask, binaries:       binaries?,
                                    verbose:        verbose?,
                                    force:          force?,
                                    skip_cask_deps: skip_cask_deps?,
                                    require_sha:    require_sha?,
                                    upgrade: true)

          begin
            # purge artifacts BUT keep metadata aside
            old_cask_installer.start_upgrade

            # install BUT do not yet save metadata

            new_cask_installer.install

            # if successful, remove old metadata and install new
            old_cask_installer.finalize_upgrade
          rescue CaskError => e
            opoo e.message
            old_cask_installer.revert_upgrade
          end
        end
      end

      def self.help
        "upgrades all outdated casks"
      end
    end
  end
end
