require "requirement"

class MinimumMacOSRequirement < Requirement
  fatal OS.mac?

  def initialize(tags)
    @version = MacOS::Version.from_symbol(tags.first)
    super
  end

  satisfy(build_env: false) { !OS.mac? || MacOS.version >= @version }

  def message
    "macOS #{@version.pretty_name} or newer is required."
  end

  def display_s
    "macOS >= #{@version}"
  end
end
