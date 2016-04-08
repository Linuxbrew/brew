#:  * `uses` [`--installed`] [`--recursive`] [`--skip-build`] [`--skip-optional`] [`--devel`|`--HEAD`] <formulae>:
#:    Show the formulae that specify <formulae> as a dependency. When given
#:    multiple formula arguments, show the intersection of formulae that use
#:    <formulae>.
#:
#:    Use `--recursive` to resolve more than one level of dependencies.
#:
#:    If `--installed` is passed, only list installed formulae.
#:
#:    By default, `uses` shows all formulae that specify <formulae> as a dependency.
#:    To skip the `:build` type dependencies, pass `--skip-build`. Similarly, pass
#:    `--skip-optional` to skip `:optional` dependencies.
#:
#:    By default, `uses` shows usages of `formula` by stable builds. To find
#:    cases where `formula` is used by development or HEAD build, pass
#:    `--devel` or `--HEAD`.

require "formula"

# `brew uses foo bar` returns formulae that use both foo and bar
# If you want the union, run the command twice and concatenate the results.
# The intersection is harder to achieve with shell tools.

module Homebrew
  def uses
    raise FormulaUnspecifiedError if ARGV.named.empty?

    used_formulae = ARGV.formulae
    formulae = (ARGV.include? "--installed") ? Formula.installed : Formula
    recursive = ARGV.flag? "--recursive"
    ignores = []
    ignores << "build?" if ARGV.include? "--skip-build"
    ignores << "optional?" if ARGV.include? "--skip-optional"

    uses = formulae.select do |f|
      used_formulae.all? do |ff|
        begin
          if recursive
            deps = f.recursive_dependencies do |dependent, dep|
              Dependency.prune if ignores.any? { |ignore| dep.send(ignore) } && !dependent.build.with?(dep)
            end
            reqs = f.recursive_requirements do |dependent, req|
              Requirement.prune if ignores.any? { |ignore| req.send(ignore) } && !dependent.build.with?(req)
            end
            deps.any? { |dep| dep.to_formula.full_name == ff.full_name rescue dep.name == ff.name } ||
            reqs.any? { |req| req.name == ff.name || [ff.name, ff.full_name].include?(req.default_formula) }
          else
            deps = f.deps.reject do |dep|
              ignores.any? { |ignore| dep.send(ignore) }
            end
            reqs = f.requirements.reject do |req|
              ignores.any? { |ignore| req.send(ignore) }
            end
            deps.any? { |dep| dep.to_formula.full_name == ff.full_name rescue dep.name == ff.name } ||
            reqs.any? { |req| req.name == ff.name || [ff.name, ff.full_name].include?(req.default_formula) }
          end
        rescue FormulaUnavailableError
          # Silently ignore this case as we don't care about things used in
          # taps that aren't currently tapped.
        end
      end
    end

    puts_columns uses.map(&:full_name)
  end
end
