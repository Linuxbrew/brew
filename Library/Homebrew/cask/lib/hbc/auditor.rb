module Hbc
  class Auditor
    def self.audit(cask, audit_download: false, check_token_conflicts: false, commit_range: nil)
      new(cask, audit_download, check_token_conflicts, commit_range).audit
    end

    attr_reader :cask, :commit_range

    def initialize(cask, audit_download, check_token_conflicts, commit_range)
      @cask = cask
      @audit_download = audit_download
      @commit_range = commit_range
      @check_token_conflicts = check_token_conflicts
    end

    def audit_download?
      @audit_download
    end

    def check_token_conflicts?
      @check_token_conflicts
    end

    def audit
      if !ARGV.value("language") && language_blocks
        audit_all_languages
      else
        audit_cask_instance(cask)
      end
    end

    private

    def audit_all_languages
      saved_languages = MacOS.instance_variable_get(:@languages)
      begin
        language_blocks.keys.all?(&method(:audit_languages))
      ensure
        MacOS.instance_variable_set(:@languages, saved_languages)
      end
    end

    def audit_languages(languages)
      ohai "Auditing language: #{languages.map { |lang| "'#{lang}'" }.join(", ")}"
      MacOS.instance_variable_set(:@languages, languages)
      audit_cask_instance(CaskLoader.load_from_file(cask.sourcefile_path))
    ensure
      CLI::Cleanup.run(cask.token) if audit_download?
    end

    def audit_cask_instance(cask)
      download = audit_download? && Download.new(cask)
      audit = Audit.new(cask, download:              download,
                              check_token_conflicts: check_token_conflicts?,
                              commit_range: commit_range)
      audit.run!
      puts audit.summary
      audit.success?
    end

    def language_blocks
      cask.instance_variable_get(:@dsl).instance_variable_get(:@language_blocks)
    end
  end
end
