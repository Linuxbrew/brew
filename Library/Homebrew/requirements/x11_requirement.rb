require "requirement"

class X11Requirement < Requirement
  include Comparable

  fatal true
  cask "xquartz"
  download "https://xquartz.macosforge.org"

  env { ENV.x11 }

  def initialize(name = "x11", tags = [])
    @name = name
    # no-op on version specified as a tag argument
    tags.shift if /(\d\.)+\d/ =~ tags.first
    super(tags)
  end

  def min_version
    # TODO: remove in https://github.com/Homebrew/brew/pull/3483
    return Version::NULL unless OS.mac?

    MacOS::XQuartz.minimum_version
  end

  satisfy build_env: false do
    # TODO: remove in https://github.com/Homebrew/brew/pull/3483
    next false unless OS.mac?

    next false unless MacOS::XQuartz.installed?
    min_version <= MacOS::XQuartz.version
  end

  def message
    s = "XQuartz #{min_version} (or newer) is required to install this formula."
    s += super
    s
  end

  def <=>(other)
    return unless other.is_a? X11Requirement
    0
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect}>"
  end
end
