require "requirement"

class X11Requirement < Requirement
  module Compat
    def initialize(tags = [])
      if tags.first.to_s.match?(/(\d\.)+\d/)
        odisabled('depends_on :x11 => "X.Y.Z"')
      end

      super(tags)
    end
  end

  prepend Compat
end
