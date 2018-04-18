require "requirement"

class OsxfuseRequirement < Requirement
  cask "osxfuse"
  fatal true
end

class NonBinaryOsxfuseRequirement < Requirement
  fatal false
end

require "extend/os/requirements/osxfuse_requirement"
