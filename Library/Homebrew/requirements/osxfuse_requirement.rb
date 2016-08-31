require "requirement"

class MacOsxfuseRequirement < Requirement
  fatal true
  cask "osxfuse"
  download "https://osxfuse.github.io/"

  satisfy(:build_env => false) { self.class.binary_osxfuse_installed? }

  def self.binary_osxfuse_installed?
    File.exist?("/usr/local/include/osxfuse/fuse.h") &&
      !File.symlink?("/usr/local/include/osxfuse")
  end

  env do
    ENV.append_path "PKG_CONFIG_PATH", HOMEBREW_LIBRARY/"Homebrew/os/mac/pkgconfig/fuse"
  end
end

class LibfuseRequirement < Requirement
  fatal true
  default_formula "libfuse"
  satisfy(:build_env => false) { Formula["libfuse"].installed? }
  def self.binary_osxfuse_installed?
    false
  end
end

OsxfuseRequirement = OS.mac? ? MacOsxfuseRequirement : LibfuseRequirement

class NonBinaryOsxfuseRequirement < Requirement
  fatal true
  satisfy(:build_env => false) { HOMEBREW_PREFIX.to_s != "/usr/local" || !OsxfuseRequirement.binary_osxfuse_installed? }

  def message
    <<-EOS.undent
      osxfuse is already installed from the binary distribution and
      conflicts with this formula.
    EOS
  end
end
