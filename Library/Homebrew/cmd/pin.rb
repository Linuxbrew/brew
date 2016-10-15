#:  * `pin` <formulae>:
#:    Pin the specified <formulae>, preventing them from being upgraded when
#:    issuing the `brew upgrade` command. See also `unpin`.

require "formula"

module Homebrew
  module_function

  def pin
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        opoo "#{f.name} already pinned"
      elsif !f.pinnable?
        onoe "#{f.name} not installed"
      else
        f.pin
      end
    end
  end
end
