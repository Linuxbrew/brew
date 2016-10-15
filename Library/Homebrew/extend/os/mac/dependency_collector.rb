class DependencyCollector
  def ant_dep(tags)
    return if MacOS.version < :mavericks
    Dependency.new("ant", tags)
  end

  def xz_dep(tags)
    return if MacOS.version >= :lion
    Dependency.new("xz", tags)
  end
end
