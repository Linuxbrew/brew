require "requirement"

class GlibcRequirement < Requirement
  fatal true
  default_formula "glibc"

  def initialize
    # Bottles for Linuxbrew are built using glibc 2.19.
    @version = "2.19"
    super
  end

  satisfy {
    next true unless OS.linux?
    begin
      next true if to_dependency.installed?
    rescue FormulaUnavailableError
      # Fix for brew tests, which uses NullLoader.
      true
    end
    libc = ["/lib/x86_64-linux-gnu/libc.so.6", "/lib64/libc.so.6"].find do |s|
      Pathname.new(s).executable?
    end
    next false unless libc
    version = Utils.popen_read(libc)[/version (\d\.\d+)/, 1]
    next false unless version
    Version.new(version.to_s) >= Version.new(@version)
  }
end
