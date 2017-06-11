module Hbc
  class CLI
    class Edit < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
        raise ArgumentError, "Only one Cask can be created at a time." if args.count > 1
      end

      def run
        cask_token = args.first
        cask_path = CaskLoader.path(cask_token)

        unless cask_path.exist?
          raise CaskUnavailableError.new(cask_token, "Run #{Formatter.identifier("brew cask create #{cask_token}")} to create a new Cask.")
        end

        odebug "Opening editor for Cask #{cask_token}"
        exec_editor cask_path
      end

      def self.help
        "edits the given Cask"
      end
    end
  end
end
