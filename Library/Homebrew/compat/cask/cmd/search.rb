require "cask/cmd/abstract_command"
require "cmd/search"

module Cask
  class Cmd
    module Compat
      class Search < AbstractCommand
        def run
          odisabled "`brew cask search`", "`brew search`"
        end

        def self.visible
          false
        end
      end
    end

    prepend Compat
  end
end
