require "requirement"

class MaximumMacOSRequirement < Requirement
  fatal true

  def initialize(tags)
    @version = MacOS::Version.from_symbol(tags.first)
    super
  end

  satisfy(build_env: false) { !OS.mac? || MacOS.version <= @version }

  def message
    <<-EOS.undent
      This formula either does not compile or function as expected on macOS
      versions newer than #{@version.pretty_name} due to an upstream incompatibility.
    EOS
  end

  def display_s
    "macOS <= #{@version}"
  end
end
