require "os/mac/linkage_checker"

class Formula
  def undeclared_runtime_dependencies
    if optlinked?
      keg = Keg.new(opt_prefix)
    elsif prefix.directory?
      keg = Keg.new(prefix)
    else
      return []
    end

    linkage_checker = LinkageChecker.new(keg, self)
    linkage_checker.undeclared_deps.map { |n| Dependency.new(n) }
  end
end
