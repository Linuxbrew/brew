class DependencyCollector
  def git_dep_if_needed(tags)
    Dependency.new("git", tags)
  end

  def cvs_dep_if_needed(tags)
    Dependency.new("cvs", tags)
  end

  def xz_dep_if_needed(tags)
    Dependency.new("xz", tags)
  end

  def ld64_dep_if_needed(*); end

  def zip_dep_if_needed(tags)
    Dependency.new("zip", tags)
  end

  def bzip2_dep_if_needed(tags)
    Dependency.new("bzip2", tags)
  end
end
