require "cask/lib/hbc/cli/options"

module Hbc
  class CLI
    include Options

    option "--binarydir=PATH", (lambda do |*|
      opoo <<~EOS
        Option --binarydir is obsolete!
        Homebrew-Cask now uses the same location as your Homebrew installation for executable links.
      EOS
    end)

    option "--caskroom=PATH", (lambda do |*|
      odisabled "`brew cask` with the `--caskroom` flag"
    end)
  end
end
