module Hbc
  class CLI
    class Zap < Base
      def self.run(*args)
        new(*args).run
      end

      def initialize(*args)
        @cask_tokens = self.class.cask_tokens_from(args)
        raise CaskUnspecifiedError if @cask_tokens.empty?
      end

      def run
        @cask_tokens.each do |cask_token|
          odebug "Zapping Cask #{cask_token}"
          cask = CaskLoader.load(cask_token)
          Installer.new(cask).zap
        end
      end

      def self.help
        "zaps all files associated with the given Cask"
      end
    end
  end
end
