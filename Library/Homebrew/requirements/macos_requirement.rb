class MacOSRequirement < Requirement
  fatal true

  satisfy(build_env: false) { OS.mac? }

  def message
    "macOS is required."
  end
end
