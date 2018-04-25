require "requirement"

class OsxfuseRequirement < Requirement
  cask "osxfuse"
  fatal true
end

require "extend/os/requirements/osxfuse_requirement"
