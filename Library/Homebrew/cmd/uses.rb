#:  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-test`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] <formulae>:
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
#:    `--include-build`, to include the `:test` type dependencies, pass
#:    `--include-test` and to include `:optional` dependencies pass
#:    `--include-optional`. To skip `:recommended` type dependencies, pass
#:    `--skip-recommended`.
#:
#:    By default, `uses` shows usage of <formulae> by stable builds. To find
#:    cases where <formulae> is used by development or HEAD build, pass
#:    `--devel` or `--HEAD`.

require "formula"

# `brew uses foo bar` returns formulae that use both foo and bar
# If you want the union, run the command twice and concatenate the results.
# The intersection is harder to achieve with shell tools.

module Homebrew
  module_function

  def uses
    raise FormulaUnspecifiedError if ARGV.named.empty?

    used_formulae_missing = false
    used_formulae = begin
      ARGV.formulae
    rescue FormulaUnavailableError => e
      opoo e
      used_formulae_missing = true
      # If the formula doesn't exist: fake the needed formula object name.
      ARGV.named.map { |name| OpenStruct.new name: name, full_name: name }
    end

    formulae = ARGV.include?("--installed") ? Formula.installed : Formula
    recursive = ARGV.flag? "--recursive"
    only_installed_arg = ARGV.include?("--installed") &&
                         !ARGV.include?("--include-build") &&
                         !ARGV.include?("--include-test") &&
                         !ARGV.include?("--include-optional") &&
                         !ARGV.include?("--skip-recommended")

    includes, ignores = argv_includes_ignores(ARGV)

    uses = formulae.select do |f|
      used_formulae.all? do |ff|
        begin
          deps = f.runtime_dependencies if only_installed_arg
          deps ||= if recursive
            recursive_includes(Dependency, f, includes, ignores)
          else
            reject_ignores(f.deps, ignores, includes)
          end

          deps.any? do |dep|
            begin
              dep.to_formula.full_name == ff.full_name
            rescue
              dep.name == ff.name
            end
          end
        rescue FormulaUnavailableError
          # Silently ignore this case as we don't care about things used in
          # taps that aren't currently tapped.
          next
        end
      end
    end

    return if uses.empty?

    puts Formatter.columns(uses.map(&:full_name).sort)
    odie "Missing formulae should not have dependents!" if used_formulae_missing
  end
end
