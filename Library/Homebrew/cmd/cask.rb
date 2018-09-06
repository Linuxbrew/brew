require "cask/all"

module Homebrew
  module_function

  def cask
    Cask::Cmd.run(*ARGV)
  end
end
