module Hbc
  class CLI
    class Version < AbstractCommand
      def self.command_name
        "--#{super}"
      end

      def run
        raise ArgumentError, "#{self.class.command_name} does not take arguments." unless @args.empty?
        puts Hbc.full_version
      end

      def self.help
        "displays the Homebrew-Cask version"
      end
    end
  end
end
