module Cask
  class Cmd
    class Edit < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
        raise ArgumentError, "Only one Cask can be edited at a time." if args.count > 1
      end

      def run
        exec_editor cask_path
      rescue CaskUnavailableError => e
        reason = e.reason.empty? ? "" : "#{e.reason} "
        reason.concat("Run #{Formatter.identifier("brew cask create #{e.token}")} to create a new Cask.")
        raise e.class.new(e.token, reason)
      end

      def cask_path
        casks.first.sourcefile_path
      rescue CaskInvalidError
        path = CaskLoader.path(args.first)
        return path if path.file?

        raise
      end

      def self.help
        "edits the given Cask"
      end
    end
  end
end
