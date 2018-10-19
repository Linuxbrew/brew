require "requirement"

class X11Requirement < Requirement
  module Compat
    def initialize(tags = [])
      if tags.first.to_s.match?(/(\d\.)+\d/)
        # TODO: deprecate when Homebrew/homebrew-core is fixed.
        # odeprecated('depends_on :x11 => "X.Y.Z"')
        tags.shift
      end

      super(tags)
    end
  end

  prepend Compat
end
