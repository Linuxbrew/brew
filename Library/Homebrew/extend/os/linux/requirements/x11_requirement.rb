require "requirement"

Object.send(:remove_const, :X11Requirement)

class X11Requirement < Requirement
  fatal true
  default_formula "linuxbrew/xorg/xorg"

  env { ENV.x11 }

  def initialize(name = "x11", tags = [])
    @name = name
    tags.shift if tags.first =~ /(\d\.)+\d/
    super(tags)
  end

  satisfy build_env: false do
    Formula["linuxbrew/xorg/xorg"].installed?
  end
end
