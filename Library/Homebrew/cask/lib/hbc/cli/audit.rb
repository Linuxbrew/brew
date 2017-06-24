module Hbc
  class CLI
    class Audit < AbstractCommand
      option "--download",        :download,        false
      option "--token-conflicts", :token_conflicts, false

      def self.help
        "verifies installability of Casks"
      end

      def run
        casks_to_audit = args.empty? ? Hbc.all : args.map(&CaskLoader.public_method(:load))

        failed_casks = casks_to_audit.reject do |cask|
          audit(cask)
        end

        return if failed_casks.empty?
        raise CaskError, "audit failed for casks: #{failed_casks.join(" ")}"
      end

      def audit(cask)
        odebug "Auditing Cask #{cask}"
        Auditor.audit(cask, audit_download: download?, check_token_conflicts: token_conflicts?)
      end

      def self.needs_init?
        true
      end
    end
  end
end
