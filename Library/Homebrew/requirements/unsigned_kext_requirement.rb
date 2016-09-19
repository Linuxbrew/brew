require "requirement"

class UnsignedKextRequirement < Requirement
  fatal true

  satisfy(build_env: false) { MacOS.version < :yosemite }

  def message
    s = <<-EOS.undent
      Building this formula from source isn't possible due to OS X
      Yosemite (10.10) and above's strict unsigned kext ban.
    EOS
    s += super
    s
  end
end
