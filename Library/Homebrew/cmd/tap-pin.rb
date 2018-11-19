#:  * `tap-pin` <tap>:
#:    Pin <tap>, prioritizing its formulae over core when formula names are supplied
#:    by the user. See also `tap-unpin`.

require "cli_parser"

module Homebrew
  module_function

  def tap_pin_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `tap-pin` <tap>

        Pin <tap>, prioritizing its formulae over core when formula names are supplied
        by the user. See also `tap-unpin`.
      EOS
      switch :debug
    end
  end

  def tap_pin
    tap_pin_args.parse

    ARGV.named.each do |name|
      tap = Tap.fetch(name)
      raise "pinning #{tap} is not allowed" if tap.core_tap?

      tap.pin
      ohai "Pinned #{tap}"
    end
  end
end
