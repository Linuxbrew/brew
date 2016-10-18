#:  * `tap-pin` <tap>:
#:    Pin <tap>, prioritizing its formulae over core when formula names are supplied
#:    by the user. See also `tap-unpin`.

require "tap"

module Homebrew
  module_function

  def tap_pin
    ARGV.named.each do |name|
      tap = Tap.fetch(name)
      raise "pinning #{tap} is not allowed" if tap.core_tap?
      tap.pin
      ohai "Pinned #{tap}"
    end
  end
end
