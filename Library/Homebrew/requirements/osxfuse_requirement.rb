require "requirement"

class MacOsxfuseRequirement < Requirement
  fatal true
end

class LibfuseRequirement < Requirement
  fatal true
  default_formula "libfuse"
  satisfy(build_env: false) { Formula["libfuse"].installed? }
  def self.binary_osxfuse_installed?
    false
  end
end

class OsxfuseRequirement < OS.mac? ? MacOsxfuseRequirement : LibfuseRequirement
end

class NonBinaryOsxfuseRequirement < Requirement
  fatal false
end

require "extend/os/requirements/osxfuse_requirement"
