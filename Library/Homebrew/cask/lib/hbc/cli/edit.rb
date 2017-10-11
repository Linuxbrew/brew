module Hbc
  class CLI
    class Edit < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
        raise ArgumentError, "Only one Cask can be edited at a time." if args.count > 1
      end

      def run
        cask = casks.first
        cask_path = cask.sourcefile_path
        odebug "Opening editor for Cask #{cask.token}"
        exec_editor cask_path
      rescue CaskUnavailableError => e
        reason = e.reason.empty? ? "" : "#{e.reason} "
        reason.concat("Run #{Formatter.identifier("brew cask create #{e.token}")} to create a new Cask.")
        raise e.class.new(e.token, reason)
      end

      def self.help
        "edits the given Cask"
      end
    end
  end
end
