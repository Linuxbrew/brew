module Hbc
  class Auditor
    def self.audit(cask, audit_download: false, check_token_conflicts: false)
      download = audit_download && Download.new(cask)
      audit = Audit.new(cask, download:              download,
                              check_token_conflicts: check_token_conflicts)
      audit.run!
      puts audit.summary
      audit.success?
    end
  end
end
