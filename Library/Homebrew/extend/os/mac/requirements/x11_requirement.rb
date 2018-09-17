require "requirement"

class X11Requirement < Requirement
  satisfy build_env: false do
    next false unless MacOS::XQuartz.installed?

    min_version <= MacOS::XQuartz.version
  end

  undef min_version, message

  def min_version
    MacOS::XQuartz.minimum_version
  end

  def message
    "XQuartz #{min_version} (or newer) is required to install this formula. #{super}"
  end
end
