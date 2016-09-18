def ant_dep(spec, tags)
  # Always use brewed ant on Linux
  Dependency.new(spec.to_s, tags)
end
