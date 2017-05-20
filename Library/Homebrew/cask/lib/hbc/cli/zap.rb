module Hbc
  class CLI
    class Zap < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        args.each do |cask_token|
          odebug "Zapping Cask #{cask_token}"
          cask = CaskLoader.load(cask_token)
          Installer.new(cask, verbose: verbose?).zap
        end
      end

      def self.help
        "zaps all files associated with the given Cask"
      end
    end
  end
end
