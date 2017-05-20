module Hbc
  class CLI
    class Cat < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        args.each do |cask_token|
          cask_path = CaskLoader.path(cask_token)
          raise CaskUnavailableError, cask_token.to_s unless cask_path.exist?
          puts File.open(cask_path, &:read)
        end
      end

      def self.help
        "dump raw source of the given Cask to the standard output"
      end
    end
  end
end
