require "requirement"

class XorgRequirement < Requirement
  fatal true
  default_formula "linuxbrew/xorg/xorg"

  def initialize(name = "xorg", tags = [])
    @name = name
    if /(\d\.)+\d/ === tags.first
      tags.shift
    end
    super(tags)
  end

  satisfy :build_env => false do
    Formula["linuxbrew/xorg/xorg"].installed?
  end
end
