class DependencyCollector
  def ant_dep_if_needed(tags)
    return if MacOS.version < :mavericks
    Dependency.new("ant", tags)
  end

  def cvs_dep_if_needed(tags)
    return if MacOS.version < :lion
    Dependency.new("cvs", tags)
  end

  def xz_dep_if_needed(tags)
    return if MacOS.version >= :mavericks
    Dependency.new("xz", tags)
  end

  def expat_dep_if_needed(tags)
    # Tiger doesn't ship expat in /usr/lib
    return if MacOS.version > :tiger
    Dependency.new("expat", tags)
  end

  def ld64_dep_if_needed(*)
    # Tiger's ld is too old to properly link some software
    return if MacOS.version > :tiger
    LD64Dependency.new
  end
end
