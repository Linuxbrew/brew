require "cask/cmd/abstract_command"
require "cmd/--version"

module Cask
  class Cmd
    class Version < AbstractCommand
      def self.command_name
        "--#{super}"
      end

      def initialize(*)
        super
        return if args.empty?

        raise ArgumentError, "#{self.class.command_name} does not take arguments."
      end

      def run
        odisabled "`brew cask --version`", "`brew --version`"
      end

      def self.help
        "displays the Homebrew Cask version"
      end

      def self.visible
        false
      end
    end
  end
end
