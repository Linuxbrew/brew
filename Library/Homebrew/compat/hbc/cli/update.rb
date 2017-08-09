require "cask/lib/hbc/cli/abstract_command"

module Hbc
  class CLI
    class Update < AbstractCommand
      def self.run(*_ignored)
        odeprecated "`brew cask update`", "`brew update`", disable_on: Time.utc(2017, 7, 1)
        result = SystemCommand.run(HOMEBREW_BREW_FILE, args:         ["update"],
                                                       print_stderr: true,
                                                       print_stdout: true)
        exit result.exit_status
      end

      def self.visible
        false
      end

      def self.help
        "a synonym for 'brew update'"
      end
    end
  end
end
