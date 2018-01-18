require "formula_support"

class KegOnlyReason
  alias _to_s to_s

  def to_s
    case @reason
    when :provided_by_osx
      odeprecated "keg_only :provided_by_osx", "keg_only :provided_by_macos"
      @reason = :provided_by_macos
    when :shadowed_by_osx
      odeprecated "keg_only :shadowed_by_osx", "keg_only :shadowed_by_macos"
      @reason = :shadowed_by_macos
    end

    _to_s
  end
end
