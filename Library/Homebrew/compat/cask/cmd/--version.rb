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
        odeprecated "`brew cask --version`", "`brew --version`", disable_on: Time.new(2018, 10, 31)
        ARGV.clear
        Homebrew.__version
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
