# Used to track formulae that cannot be installed at the same time
FormulaConflict = Struct.new(:name, :reason)

# Used to annotate formulae that duplicate macOS provided software
# or cause conflicts when linked in.
class KegOnlyReason
  attr_reader :reason

  def initialize(reason, explanation)
    @reason = reason
    @explanation = explanation
  end

  def valid?
    case @reason
    when :provided_pre_mountain_lion
      MacOS.version < :mountain_lion
    when :provided_pre_mavericks
      MacOS.version < :mavericks
    when :provided_pre_el_capitan
      MacOS.version < :el_capitan
    when :provided_pre_high_sierra
      MacOS.version < :high_sierra
    when :provided_until_xcode43
      MacOS::Xcode.installed? && MacOS::Xcode.version < "4.3"
    when :provided_until_xcode5
      MacOS::Xcode.installed? && MacOS::Xcode.version < "5.0"
    else
      true
    end
  end

  def to_s
    return @explanation unless @explanation.empty?
    case @reason
    when :versioned_formula then <<-EOS.undent
      this is an alternate version of another formula
    EOS
    when :provided_by_macos, :provided_by_osx then <<-EOS.undent
      macOS already provides this software and installing another version in
      parallel can cause all kinds of trouble
    EOS
    when :shadowed_by_macos, :shadowed_by_osx then <<-EOS.undent
      macOS provides similar software and installing this software in
      parallel can cause all kinds of trouble
    EOS
    when :provided_pre_mountain_lion then <<-EOS.undent
      macOS already provides this software in versions before Mountain Lion
    EOS
    when :provided_pre_mavericks then <<-EOS.undent
      macOS already provides this software in versions before Mavericks
    EOS
    when :provided_pre_el_capitan then <<-EOS.undent
      macOS already provides this software in versions before El Capitan
    EOS
    when :provided_pre_high_sierra then <<-EOS.undent
      macOS already provides this software in versions before High Sierra
    EOS
    when :provided_until_xcode43 then <<-EOS.undent
      Xcode provides this software prior to version 4.3
    EOS
    when :provided_until_xcode5 then <<-EOS.undent
      Xcode provides this software prior to version 5
    EOS
    else
      @reason
    end.strip
  end
end

# Used to annotate formulae that don't require compiling or cannot build bottle.
class BottleDisableReason
  SUPPORTED_TYPES = [:unneeded, :disable].freeze

  def initialize(type, reason)
    @type = type
    @reason = reason
  end

  def unneeded?
    @type == :unneeded
  end

  def valid?
    SUPPORTED_TYPES.include? @type
  end

  def to_s
    if unneeded?
      "This formula doesn't require compiling."
    else
      @reason
    end
  end
end
