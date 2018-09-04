require "cask/all"

module Homebrew
  module_function

  def cask
    Hbc::Cmd.run(*ARGV)
  end
end
