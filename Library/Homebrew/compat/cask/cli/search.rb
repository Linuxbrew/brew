require "cask/cli/abstract_command"
require "cmd/search"

module Hbc
  class CLI
    module Compat
      class Search < AbstractCommand
        def run
          odeprecated "`brew cask search`", "`brew search`", disable_on: Time.new(2018, 9, 30)
          Homebrew.search(args.empty? ? "--casks" : args)
        end

        def self.visible
          false
        end
      end
    end

    prepend Compat
  end
end
