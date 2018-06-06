require "help"

module Homebrew
  def help(cmd = nil, flags = {})
    Help.help(cmd, flags)
  end
end
