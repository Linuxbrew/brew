require "cask/lib/hbc/cli/options"

module Hbc
  class CLI
    include Options

    option "--binarydir=PATH", (lambda do |*|
      opoo <<-EOS.undent
        Option --binarydir is obsolete!
        Homebrew-Cask now uses the same location as your Homebrew installation for executable links.
      EOS
    end)

    option "--caskroom=PATH", (lambda do |value|
      Hbc.caskroom = value
      odeprecated "`brew cask` with the `--caskroom` flag", disable_on: Time.utc(2017, 10, 31)
    end)
  end
end
