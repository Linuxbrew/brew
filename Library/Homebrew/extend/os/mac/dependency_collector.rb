require "os/mac/ld64_dependency"

class DependencyCollector
  undef git_dep_if_needed, subversion_dep_if_needed, cvs_dep_if_needed,
        xz_dep_if_needed, unzip_dep_if_needed, bzip2_dep_if_needed,
        ld64_dep_if_needed

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

  def unzip_dep_if_needed(tags); end

  def bzip2_dep_if_needed(tags); end

  def ld64_dep_if_needed(*)
    # Tiger's ld is too old to properly link some software
    return if MacOS.version > :tiger

    LD64Dependency.new
  end
end
