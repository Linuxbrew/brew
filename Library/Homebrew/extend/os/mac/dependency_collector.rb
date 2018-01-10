require "os/mac/ld64_dependency"

class DependencyCollector
  def git_dep_if_needed(tags)
    return if MacOS.version >= :lion
    Dependency.new("git", tags)
  end

  def subversion_dep_if_needed(tags); end

  def cvs_dep_if_needed(tags)
    return if MacOS.version < :lion
    Dependency.new("cvs", tags)
  end

  def xz_dep_if_needed(tags)
    return if MacOS.version >= :mavericks
    Dependency.new("xz", tags)
  end

  def ld64_dep_if_needed(*)
    # Tiger's ld is too old to properly link some software
    return if MacOS.version > :tiger
    LD64Dependency.new
  end
end
