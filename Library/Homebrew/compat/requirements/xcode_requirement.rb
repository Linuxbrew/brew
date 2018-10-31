require "requirement"

class XcodeRequirement < Requirement
  module Compat
    def initialize(tags = [])
      @version = if tags.first.to_s.match?(/(\d\.)+\d/)
        tags.shift
      else
        tags.find do |tag|
          next unless tag.to_s.match?(/(\d\.)+\d/)
          odeprecated('depends_on :xcode => [..., "X.Y.Z"]')
          tags.delete(tag)
        end
      end

      super(tags)
    end
  end

  prepend Compat
end
