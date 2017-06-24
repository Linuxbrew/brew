module Hbc
  class CLI
    class Install < AbstractCommand
      option "--force",          :force,          false
      option "--skip-cask-deps", :skip_cask_deps, false
      option "--require-sha",    :require_sha,    false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        retval = install_casks
        # retval is ternary: true/false/nil

        raise CaskError, "nothing to install" if retval.nil?
        raise CaskError, "install incomplete" unless retval
      end

      def install_casks
        count = 0
        args.each do |cask_token|
          begin
            cask = CaskLoader.load(cask_token)
            Installer.new(cask, binaries:       binaries?,
                                verbose: verbose?,
                                force:          force?,
                                skip_cask_deps: skip_cask_deps?,
                                require_sha:    require_sha?).install
            count += 1
          rescue CaskAlreadyInstalledError => e
            opoo e.message
            count += 1
          rescue CaskAlreadyInstalledAutoUpdatesError => e
            opoo e.message
            count += 1
          rescue CaskUnavailableError => e
            self.class.warn_unavailable_with_suggestion cask_token, e
          rescue CaskNoShasumError => e
            opoo e.message
            count += 1
          rescue CaskError => e
            onoe e.message
          end
        end

        count.zero? ? nil : count == args.length
      end

      def self.warn_unavailable_with_suggestion(cask_token, e)
        exact_match, partial_matches = Search.search(cask_token)
        error_message = e.message
        if exact_match
          error_message.concat(". Did you mean:\n#{exact_match}")
        elsif !partial_matches.empty?
          error_message.concat(". Did you mean one of:\n")
                       .concat(Formatter.columns(partial_matches.take(20)))
        end
        onoe error_message
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
