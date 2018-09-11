module Cask
  class Cmd
    class Outdated < AbstractCommand
      option "--greedy", :greedy, false
      option "--quiet",  :quiet, false

      def initialize(*)
        super
        self.verbose = ($stdout.tty? || verbose?) && !quiet?
      end

      def run
        casks(alternative: -> { Caskroom.casks }).each do |cask|
          odebug "Checking update info of Cask #{cask}"
          self.class.list_if_outdated(cask, greedy?, verbose?)
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
