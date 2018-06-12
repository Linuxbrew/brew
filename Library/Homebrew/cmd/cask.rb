require "hbc"

module Homebrew
  module_function

  def cask
    odie "Homebrew Cask is only supported on macOS" unless OS.mac?
    Hbc::CLI.run(*ARGV)
  end
end
