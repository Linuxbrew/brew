module Hbc
  class Auditor
    def self.audit(cask, audit_download: false, check_token_conflicts: false)
      if !ARGV.value("language") &&
        languages_blocks = cask.instance_variable_get(:@dsl).instance_variable_get(:@language_blocks)
        begin
          saved_languages = MacOS.instance_variable_get(:@languages)

          languages_blocks.keys.map { |languages|
            ohai "Auditing language: #{languages.map { |lang| "'#{lang}'" }.join(", ")}"
            MacOS.instance_variable_set(:@languages, languages)
            audit_cask_instance(Hbc.load(cask.sourcefile_path), audit_download, check_token_conflicts)
            CLI::Cleanup.run(cask.token) if audit_download
          }.all?
        ensure
          MacOS.instance_variable_set(:@languages, saved_languages)
        end
      else
        audit_cask_instance(cask, audit_download, check_token_conflicts)
      end
    end

    def self.audit_cask_instance(cask, audit_download, check_token_conflicts)
      download = audit_download && Download.new(cask)
      audit = Audit.new(cask, download:              download,
                              check_token_conflicts: check_token_conflicts)
      audit.run!
      puts audit.summary
      audit.success?
    end
  end
end
