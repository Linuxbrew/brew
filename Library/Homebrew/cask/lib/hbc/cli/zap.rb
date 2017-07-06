module Hbc
  class CLI
    class Zap < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        raise CaskError, "Zap incomplete." if zap_casks == :incomplete
      end

      def zap_casks
        casks.each do |cask|
          odebug "Zapping Cask #{cask}"
          Installer.new(cask, verbose: verbose?).zap
        end
      end

      def self.help
        "zaps all files associated with the given Cask"
      end
    end
  end
end
