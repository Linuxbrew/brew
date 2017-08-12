#:  * `unpin` <formulae>:
#:    Unpin <formulae>, allowing them to be upgraded by `brew upgrade <formulae>`.
#:    See also `pin`.

require "formula"

module Homebrew
  module_function

  def unpin
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each do |f|
      if f.pinned?
        f.unpin
      elsif !f.pinnable?
        onoe "#{f.name} not installed"
      else
        opoo "#{f.name} not pinned"
      end
    end
  end
end
