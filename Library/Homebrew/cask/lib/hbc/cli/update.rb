module Hbc
  class CLI
    class Update < Base
      def self.run(*_ignored)
        result = SystemCommand.run(HOMEBREW_BREW_FILE,
                                   args: ["update"])
        # TODO: separating stderr/stdout is undesirable here.
        #       Hbc::SystemCommand should have an option for plain
        #       unbuffered output.
        print result.stdout
        $stderr.print result.stderr
        exit result.exit_status
      end

      def self.help
        "a synonym for 'brew update'"
      end
    end
  end
end
