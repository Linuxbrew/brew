require "hbc"

module Homebrew
  module_function

  def cask
    Hbc::CLI.run(*ARGV)
  end
end
