module Hbc
  class CLI
    class Zap < AbstractCommand
      option "--force", :force, false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        casks.each do |cask|
          odebug "Zapping Cask #{cask}"
          Installer.new(cask, verbose: verbose?, force: force?).zap
        end
      end

      def self.help
        "zaps all files associated with the given Cask"
      end
    end
  end
end
