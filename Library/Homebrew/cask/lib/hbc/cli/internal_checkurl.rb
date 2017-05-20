module Hbc
  class CLI
    class InternalCheckurl < AbstractInternalCommand
      def run
        casks_to_check = @args.empty? ? Hbc.all : @args.map { |arg| CaskLoader.load(arg) }
        casks_to_check.each do |cask|
          odebug "Checking URL for Cask #{cask}"
          checker = UrlChecker.new(cask)
          checker.run
          puts checker.summary
        end
      end

      def self.help
        "checks for bad Cask URLs"
      end
    end
  end
end
