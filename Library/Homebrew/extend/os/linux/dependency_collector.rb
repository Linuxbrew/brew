class DependencyCollector
  def xz_dep_if_needed(tags)
    Dependency.new("xz", tags) unless which("xz")
  end
end
