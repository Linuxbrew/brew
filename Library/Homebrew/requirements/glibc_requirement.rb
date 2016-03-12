require "requirement"

class GlibcRequirement < Requirement
  fatal true
  default_formula "glibc"
  @@system_version = nil

  def initialize
    # Bottles for Linuxbrew are built using glibc 2.19.
    @version = "2.19"
    super
  end

  def self.system_version
    return @@system_version if @@system_version
    libc = ["/lib/x86_64-linux-gnu/libc.so.6", "/lib64/libc.so.6", "/lib/libc.so.6", "/lib/arm-linux-gnueabihf/libc.so.6"].find do |s|
      Pathname.new(s).executable?
    end
    raise "Unable to locate the system's glibc" unless libc
    version = Utils.popen_read(libc)[/version (\d\.\d+)/, 1]
    raise "Unable to determine the system's glibc version" unless version
    @@system_version = version
  end

  satisfy(:build_env => false) {
    next true unless OS.linux?
    begin
      next true if to_dependency.installed?
    rescue FormulaUnavailableError
      # Fix for brew tests, which uses NullLoader.
      true
    end
    Version.new(self.class.system_version.to_s) >= Version.new(@version)
  }
end
