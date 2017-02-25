class LinuxRequirement < Requirement
  fatal true

  satisfy(build_env: false) { OS.linux? }

  def message
    "Linux is required."
  end
end
