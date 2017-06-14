module Hbc
  class CLI
    class Audit < AbstractCommand
      option "--download",        :download,        false
      option "--token-conflicts", :token_conflicts, false

      def self.help
        "verifies installability of Casks"
      end

      def run
        failed_casks = casks(alternative: -> { Hbc.all })
                       .reject { |cask| audit(cask) }

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
