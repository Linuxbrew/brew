#:  * `home`:
#:    Open Homebrew's own homepage in a browser.
#:
#:  * `home` <formula>:
#:    Open <formula>'s homepage in a browser.

require "cli_parser"

module Homebrew
  module_function

  def home_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `home` [<formula>]

        Open <formula>'s homepage in a browser. If no formula is provided,
        open Homebrew's own homepage in a browser.
      EOS
      switch :debug
    end
  end

  def home
    home_args.parse

    if args.remaining.empty?
      exec_browser HOMEBREW_WWW
    else
      exec_browser(*ARGV.formulae.map(&:homepage))
    end
  end
end
