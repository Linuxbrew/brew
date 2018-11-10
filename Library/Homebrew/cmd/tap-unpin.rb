#:  * `tap-unpin` <tap>:
#:    Unpin <tap> so its formulae are no longer prioritized. See also `tap-pin`.

require "cli_parser"

module Homebrew
  module_function

  def tap_unpin_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `tap-unpin` <tap>

        Unpin <tap> so its formulae are no longer prioritized. See also `tap-pin`.
      EOS
      switch :debug
    end
  end

  def tap_unpin
    tap_unpin_args.parse

    ARGV.named.each do |name|
      tap = Tap.fetch(name)
      raise "unpinning #{tap} is not allowed" if tap.core_tap?

      tap.unpin
      ohai "Unpinned #{tap}"
    end
  end
end
