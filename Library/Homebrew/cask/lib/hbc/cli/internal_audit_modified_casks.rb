module Hbc
  class CLI
    class InternalAuditModifiedCasks < AbstractInternalCommand
      RELEVANT_STANZAS = [:version, :sha256, :url, :appcast].freeze

      option "--cleanup", :cleanup, false

      def self.needs_init?
        true
      end

      attr_accessor :commit_range
      private :commit_range=

      def initialize(*)
        super

        if args.count != 1
          raise ArgumentError, <<-EOS.undent
            This command requires exactly one argument.

            #{self.class.usage}
          EOS
        end

        @commit_range = args.first
      end

      def self.help
        "audit all modified Casks in a given commit range"
      end

      def self.usage
        <<-EOS.undent
          Usage: brew cask _audit_modified_casks [options...] <commit range>

          Given a range of Git commits, find any Casks that were modified and run `brew
          cask audit' on them. If the `url', `version', or `sha256' stanzas were modified,
          run with the `--download' flag to verify the hash.

          Options:
            -c, --cleanup
              Remove all cached downloads. Use with care.
        EOS
      end

      def run
        Dir.chdir git_root do
          modified_cask_files.zip(modified_casks).each do |cask_file, cask|
            audit(cask, cask_file)
            Cleanup.run(cask) if cleanup?
          end
        end
        report_failures
      end

      def git_root
        @git_root ||= git("rev-parse", "--show-toplevel")
      end

      def modified_cask_files
        @modified_cask_files ||= git_filter_cask_files("AM")
      end

      def added_cask_files
        @added_cask_files ||= git_filter_cask_files("A")
      end

      def git_filter_cask_files(filter)
        git("diff", "--name-only", "--diff-filter=#{filter}", commit_range,
            "--", Pathname.new(git_root).join("Casks", "*.rb").to_s).split("\n")
      end

      def modified_casks
        return @modified_casks if defined? @modified_casks
        @modified_casks = modified_cask_files.map { |f| CaskLoader.load(f) }
        if @modified_casks.any?
          num_modified = @modified_casks.size
          ohai "#{Formatter.pluralize(num_modified, "modified cask")}: " \
            "#{@modified_casks.join(" ")}"
        end
        @modified_casks
      end

      def audit(cask, cask_file)
        audit_download = audit_download?(cask, cask_file)
        check_token_conflicts = added_cask_files.include?(cask_file)
        success = Auditor.audit(cask, audit_download:        audit_download,
                                      check_token_conflicts: check_token_conflicts,
                                      commit_range: commit_range)
        failed_casks << cask unless success
      end

      def failed_casks
        @failed_casks ||= []
      end

      def audit_download?(cask, cask_file)
        cask.sha256 != :no_check && relevant_stanza_modified?(cask_file)
      end

      def relevant_stanza_modified?(cask_file)
        out = git("diff", commit_range, "--", cask_file)
        out =~ /^\+\s*(#{RELEVANT_STANZAS.join('|')})/
      end

      def git(*args)
        odebug ["git", *args].join(" ")
        out, err, status = Open3.capture3("git", *args)
        return out.chomp if status.success?
        odie err.chomp
      end

      def report_failures
        return if failed_casks.empty?
        num_failed = failed_casks.size
        odie "audit failed for #{Formatter.pluralize(num_failed, "cask")}: " \
          "#{failed_casks.join(" ")}"
      end
    end
  end
end
