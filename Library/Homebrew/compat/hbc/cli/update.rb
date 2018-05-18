require "cask/lib/hbc/cli/abstract_command"

module Hbc
  class CLI
    module Compat
      class Update < AbstractCommand
        def self.run(*_ignored)
          odisabled "`brew cask update`", "`brew update`"
        end

        def self.visible
          false
        end
      end
    end

    prepend Compat
  end
end
