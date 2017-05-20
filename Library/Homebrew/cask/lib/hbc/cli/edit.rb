module Hbc
  class CLI
    class Edit < AbstractCommand
      def run
        cask_tokens = self.class.cask_tokens_from(@args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        # only respects the first argument
        cask_token = cask_tokens.first.sub(/\.rb$/i, "")
        cask_path = CaskLoader.path(cask_token)
        odebug "Opening editor for Cask #{cask_token}"
        unless cask_path.exist?
          raise CaskUnavailableError, %Q(#{cask_token}, run "brew cask create #{cask_token}" to create a new Cask)
        end
        exec_editor cask_path
      end

      def self.help
        "edits the given Cask"
      end
    end
  end
end
