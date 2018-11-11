#:  * `untap` <tap>:
#:    Remove a tapped repository.

require "cli_parser"

module Homebrew
  module_function

  def untap_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `untap` <tap>

        Remove a tapped repository.
      EOS
      switch :debug
    end
  end

  def untap
    untap_args.parse

    raise "Usage is `brew untap <tap-name>`" if args.remaining.empty?

    ARGV.named.each do |tapname|
      tap = Tap.fetch(tapname)
      raise "untapping #{tap} is not allowed" if tap.core_tap?

      tap.uninstall
    end
  end
end
