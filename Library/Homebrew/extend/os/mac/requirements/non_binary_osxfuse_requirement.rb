require "requirement"

class NonBinaryOsxfuseRequirement < Requirement
  fatal true
  satisfy(build_env: false) do
    HOMEBREW_PREFIX.to_s != "/usr/local" || !OsxfuseRequirement.binary_osxfuse_installed?
  end

  def message
    <<~EOS
      osxfuse is already installed from the binary distribution and
      conflicts with this formula.
    EOS
  end
end
