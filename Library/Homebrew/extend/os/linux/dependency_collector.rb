class DependencyCollector
  def ant_dep(spec, tags)
    Dependency.new(spec.to_s, tags)
  end
end
