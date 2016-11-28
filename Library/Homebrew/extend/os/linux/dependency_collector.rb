class DependencyCollector
  def ant_dep(tags)
    Dependency.new("ant", tags)
  end

  def xz_dep(tags)
    Dependency.new("xz", tags)
  end
end
