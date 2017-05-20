module Hbc
  class CLI
    class Audit < AbstractCommand
      def self.help
        "verifies installability of Casks"
      end

      def self.run(*args)
        new(*args).run
      end

      def initialize(*args, auditor: Auditor)
        @args = args
        @auditor = auditor
      end

      def run
        failed_casks = []

        casks_to_audit.each do |cask|
          next if audit(cask)
          failed_casks << cask
        end

        return if failed_casks.empty?
        raise CaskError, "audit failed for casks: #{failed_casks.join(" ")}"
      end

      def audit(cask)
        odebug "Auditing Cask #{cask}"
        @auditor.audit(cask, audit_download:        audit_download?,
                             check_token_conflicts: check_token_conflicts?)
      end

      def audit_download?
        @args.include?("--download")
      end

      def check_token_conflicts?
        @args.include?("--token-conflicts")
      end

      def casks_to_audit
        if cask_tokens.empty?
          Hbc.all
        else
          cask_tokens.map { |token| CaskLoader.load(token) }
        end
      end

      def cask_tokens
        @cask_tokens ||= self.class.cask_tokens_from(@args)
      end

      def self.needs_init?
        true
      end
    end
  end
end
