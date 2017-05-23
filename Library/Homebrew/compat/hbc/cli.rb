require "cask/lib/hbc/cli/options"

module Hbc
  class CLI
    include Options

    option "--caskroom=PATH", (lambda do |value|
      Hbc.caskroom = value
      odeprecated "`brew cask` with the `--caskroom` flag", disable_on: Time.utc(2017, 10, 31)
    end)
  end
end
