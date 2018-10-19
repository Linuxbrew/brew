require "requirement"

class MacOSRequirement < Requirement
  fatal true

  def initialize(tags = [])
    @version = MacOS::Version.from_symbol(tags.shift) unless tags.empty?
    super(tags)
  end

  def minimum_version_specified?
    OS.mac? && @version
  end

  satisfy(build_env: false) do
    next MacOS.version >= @version if minimum_version_specified?
    next true if OS.mac?
    next true if @version

    false
  end

  def message
    return "macOS is required." unless minimum_version_specified?

    "macOS #{@version.pretty_name} or newer is required."
  end

  def display_s
    return "macOS is required" unless minimum_version_specified?

    "macOS >= #{@version}"
  end
end
