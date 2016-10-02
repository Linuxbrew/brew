module Hbc
  class CLI
    class Install < Base
      def self.run(*args)
        cask_tokens = cask_tokens_from(args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        force = args.include? "--force"
        skip_cask_deps = args.include? "--skip-cask-deps"
        require_sha = args.include? "--require-sha"
        retval = install_casks cask_tokens, force, skip_cask_deps, require_sha
        # retval is ternary: true/false/nil

        raise CaskError, "nothing to install" if retval.nil?
        raise CaskError, "install incomplete" unless retval
      end

      def self.install_casks(cask_tokens, force, skip_cask_deps, require_sha)
        count = 0
        cask_tokens.each do |cask_token|
          begin
            cask = Hbc.load(cask_token)
            Installer.new(cask,
                               force:          force,
                               skip_cask_deps: skip_cask_deps,
                               require_sha:    require_sha).install
            count += 1
          rescue CaskAlreadyInstalledError => e
            opoo e.message
            count += 1
          rescue CaskAlreadyInstalledAutoUpdatesError => e
            opoo e.message
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
