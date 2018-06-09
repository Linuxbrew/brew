require "hbc/cli/abstract_command"
require "cmd/search"

module Hbc
  class CLI
    module Compat
      class Search < AbstractCommand
        def run
          odeprecated "`brew cask search`", "`brew search`"
          Homebrew.search(args)
        end

        def self.visible
          false
        end
      end
    end

    prepend Compat
  end
end
