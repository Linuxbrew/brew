require "requirement"

class OsxfuseRequirement < Requirement
  fatal true
end

class NonBinaryOsxfuseRequirement < Requirement
  fatal false
end

require "extend/os/requirements/osxfuse_requirement"
