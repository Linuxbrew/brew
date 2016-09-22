class DependencyCollector
  def ant_dep(spec, tags)
    return if MacOS.version < :mavericks
    Dependency.new(spec.to_s, tags)
  end
end
