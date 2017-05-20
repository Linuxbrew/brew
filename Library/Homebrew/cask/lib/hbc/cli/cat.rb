module Hbc
  class CLI
    class Cat < AbstractCommand
      def run
        cask_tokens = self.class.cask_tokens_from(@args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        # only respects the first argument
        cask_token = cask_tokens.first.sub(/\.rb$/i, "")
        cask_path = CaskLoader.path(cask_token)
        raise CaskUnavailableError, cask_token.to_s unless cask_path.exist?
        puts File.open(cask_path, &:read)
      end

      def self.help
        "dump raw source of the given Cask to the standard output"
      end
    end
  end
end
