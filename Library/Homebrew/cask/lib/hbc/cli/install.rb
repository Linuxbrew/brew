module Hbc
  class CLI
    class Install < AbstractCommand
      option "--force",          :force,          false
      option "--skip-cask-deps", :skip_cask_deps, false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        odie "Installing casks is supported only on macOS" unless OS.mac?
        casks.each do |cask|
          begin
            Installer.new(cask, binaries:       binaries?,
                                verbose:        verbose?,
                                force:          force?,
                                skip_cask_deps: skip_cask_deps?,
                                require_sha:    require_sha?).install
          rescue CaskAlreadyInstalledError => e
            opoo e.message
          end
        end
      end

      def self.help
        "installs the given Cask"
      end

      def self.needs_init?
        true
      end
    end
  end
end
