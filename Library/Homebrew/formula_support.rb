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
    ![:provided_by_macos, :provided_by_osx, :shadowed_by_macos].include?(@reason)
  end

  def to_s
    return @explanation unless @explanation.empty?

    case @reason
    when :versioned_formula
      <<~EOS
        this is an alternate version of another formula
      EOS
    when :provided_by_macos
      <<~EOS
        macOS already provides this software and installing another version in
        parallel can cause all kinds of trouble
      EOS
    when :shadowed_by_macos
      <<~EOS
        macOS provides similar software and installing this software in
        parallel can cause all kinds of trouble
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
    return "This formula doesn't require compiling." if unneeded?

    @reason
  end
end

require "extend/os/formula_support"
