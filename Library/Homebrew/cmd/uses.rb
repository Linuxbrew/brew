#:  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] <formulae>:
#:    Show the formulae that specify <formulae> as a dependency. When given
#:    multiple formula arguments, show the intersection of formulae that use
#:    <formulae>.
#:
#:    Use `--recursive` to resolve more than one level of dependencies.
#:
#:    If `--installed` is passed, only list installed formulae.
#:
#:    By default, `uses` shows all formulae that specify <formulae> as a required
#:    or recommended dependency. To include the `:build` type dependencies, pass
#:    `--include-build`. Similarly, pass `--include-optional` to include `:optional`
#:    dependencies. To skip `:recommended` type dependencies, pass `--skip-recommended`.
#:
#:    By default, `uses` shows usages of `formula` by stable builds. To find
#:    cases where `formula` is used by development or HEAD build, pass
#:    `--devel` or `--HEAD`.

require "formula"

# `brew uses foo bar` returns formulae that use both foo and bar
# If you want the union, run the command twice and concatenate the results.
# The intersection is harder to achieve with shell tools.

module Homebrew
  module_function

  def uses
    raise FormulaUnspecifiedError if ARGV.named.empty?

    used_formulae = ARGV.formulae
    formulae = ARGV.include?("--installed") ? Formula.installed : Formula
    recursive = ARGV.flag? "--recursive"
    includes = []
    ignores = []
    if ARGV.include? "--include-build"
      includes << "build?"
    else
      ignores << "build?"
    end
    if ARGV.include? "--include-optional"
      includes << "optional?"
    else
      ignores << "optional?"
    end
    ignores << "recommended?" if ARGV.include? "--skip-recommended"

    uses = formulae.select do |f|
      used_formulae.all? do |ff|
        begin
          if recursive
            deps = f.recursive_dependencies do |dependent, dep|
              if dep.recommended?
                Dependency.prune if ignores.include?("recommended?") || dependent.build.without?(dep)
              elsif dep.optional?
                Dependency.prune if !includes.include?("optional?") && !dependent.build.with?(dep)
              elsif dep.build?
                Dependency.prune unless includes.include?("build?")
              end
            end
            reqs = f.recursive_requirements do |dependent, req|
              if req.recommended?
                Requirement.prune if ignores.include?("recommended?") || dependent.build.without?(req)
              elsif req.optional?
                Requirement.prune if !includes.include?("optional?") && !dependent.build.with?(req)
              elsif req.build?
                Requirement.prune unless includes.include?("build?")
              end
            end
          else
            deps = f.deps.reject do |dep|
              ignores.any? { |ignore| dep.send(ignore) } && !includes.any? { |include| dep.send(include) }
            end
            reqs = f.requirements.reject do |req|
              ignores.any? { |ignore| req.send(ignore) } && !includes.any? { |include| req.send(include) }
            end
          end
          next true if deps.any? do |dep|
            begin
              dep.to_formula.full_name == ff.full_name
            rescue
              dep.name == ff.name
            end
          end

          reqs.any? do |req|
            req.name == ff.name || [ff.name, ff.full_name].include?(req.default_formula)
          end
        rescue FormulaUnavailableError
          # Silently ignore this case as we don't care about things used in
          # taps that aren't currently tapped.
        end
      end
    end

    return if uses.empty?
    puts Formatter.columns(uses.map(&:full_name))
  end
end
