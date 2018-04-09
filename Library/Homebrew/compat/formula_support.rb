require "formula_support"

class KegOnlyReason
  module Compat
    def to_s
      case @reason
      when :provided_by_osx
        odisabled "keg_only :provided_by_osx", "keg_only :provided_by_macos"
      when :shadowed_by_osx
        odisabled "keg_only :shadowed_by_osx", "keg_only :shadowed_by_macos"
      end

      super
    end
  end

  prepend Compat
end
