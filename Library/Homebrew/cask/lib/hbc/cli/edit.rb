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
        cask_path = begin
          CaskLoader.load(cask_token).sourcefile_path
        rescue CaskUnavailableError => e
          reason = e.reason.empty? ? "" : "#{e.reason} "
          reason.concat("Run #{Formatter.identifier("brew cask create #{e.token}")} to create a new Cask.")
          raise e.class.new(e.token, reason)
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
