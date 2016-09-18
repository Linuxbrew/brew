def ant_dep(spec, tags)
  if MacOS.version >= :mavericks
    Dependency.new(spec.to_s, tags)
  end
end
