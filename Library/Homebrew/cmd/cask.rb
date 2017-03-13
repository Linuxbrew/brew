$LOAD_PATH.unshift("#{HOMEBREW_LIBRARY_PATH}/cask/lib")
require "hbc"

module Homebrew
  module_function

  def cask
    odie "Homebrew Cask is only supported on macOS" unless OS.mac?

    Hbc::CLI.process(ARGV)
  end
end
