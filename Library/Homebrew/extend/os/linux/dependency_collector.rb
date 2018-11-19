class DependencyCollector
  def java_dep_if_needed(tags)
    req = JavaRequirement.new(tags)
    begin
      dep = Dependency.new("openjdk", tags)
      return dep if dep.installed?
      return req if req.satisfied?
      dep
    rescue FormulaUnavailableError
      req
    end
  end
end
