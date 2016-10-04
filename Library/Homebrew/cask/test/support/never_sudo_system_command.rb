module Hbc
  class NeverSudoSystemCommand < SystemCommand
    def self.run(command, options = {})
      super(command, options.merge(sudo: false))
    end
  end
end
