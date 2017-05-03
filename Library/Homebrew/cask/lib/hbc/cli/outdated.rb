module Hbc
  class CLI
    class Outdated < Base
      def self.run(*args)
        greedy  = args.include?("--greedy")
        verbose = ($stdout.tty? || CLI.verbose?) && !args.include?("--quiet")

        cask_tokens = cask_tokens_from(args)
        casks_to_check = if cask_tokens.empty?
          Hbc.installed
        else
          cask_tokens.map { |token| CaskLoader.load(token) }
        end

        casks_to_check.each do |cask|
          odebug "Checking update info of Cask #{cask}"
          list_if_outdated(cask, greedy, verbose)
        end
      end

      def self.list_if_outdated(cask, greedy, verbose)
        return unless cask.outdated?(greedy)

        if verbose
          outdated_versions = cask.outdated_versions(greedy)
          outdated_info   = "#{cask.token} (#{outdated_versions.join(", ")})"
          current_version = cask.version.to_s
          puts "#{outdated_info} != #{current_version}"
        else
          puts cask.token
        end
      end

      def self.help
        "list the outdated installed Casks"
      end
    end
  end
end
