require "requirement"

class X11Requirement < Requirement
  include Comparable

  fatal true

  env { ENV.x11 }

  def initialize(name = "x11", tags = [])
    @name = name
    # no-op on version specified as a tag argument
    tags.shift if /(\d\.)+\d/ =~ tags.first
    super(tags)
  end

  def min_version
    "1.12.2"
  end

  def min_xdpyinfo_version
    "1.3.0"
  end

  satisfy build_env: false do
    if which_xorg = which("Xorg")
      version = Utils.popen_read which_xorg, "-version", err: :out
      next false unless $CHILD_STATUS.success?
      version = version[/X Server (\d+\.\d+\.\d+)/, 1]
      next false unless version
      Version.new(version) >= min_version
    elsif which_xdpyinfo = which("xdpyinfo")
      version = Utils.popen_read which_xdpyinfo, "-version"
      next false unless $CHILD_STATUS.success?
      version = version[/^xdpyinfo (\d+\.\d+\.\d+)/, 1]
      next false unless version
      Version.new(version) >= min_xdpyinfo_version
    else
      false
    end
  end

  def message
    "X11 is required to install this formula, either Xorg #{min_version} or xdpyinfo #{min_xdpyinfo_version}, or newer. #{super}"
  end

  def <=>(other)
    return unless other.is_a? X11Requirement
    0
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect}>"
  end
end

require "extend/os/requirements/x11_requirement"
