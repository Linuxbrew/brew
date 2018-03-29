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

    verbose_using_dots = !ENV["HOMEBREW_VERBOSE_USING_DOTS"].nil?
    last_dot = Time.at(0)

    uses = formulae.select do |f|
      # Print a dot every minute.
      if verbose_using_dots && (Time.now - last_dot) > 60
        last_dot = Time.now
        $stderr.print "."
        $stderr.flush
      end

      used_formulae.all? do |ff|
        begin
          deps = f.runtime_dependencies if only_installed_arg
          if recursive
            deps ||= recursive_includes(Dependency, f, includes, ignores)

            dep_formulae = deps.flat_map do |dep|
              begin
                dep.to_formula
              rescue
                []
              end
            end

            reqs_by_formula = ([f] + dep_formulae).flat_map do |formula|
              formula.requirements.map { |req| [formula, req] }
            end

            reqs_by_formula.reject! do |dependent, req|
              if req.recommended?
                ignores.include?("recommended?") || dependent.build.without?(req)
              elsif req.test?
                !includes.include?("test?")
              elsif req.optional?
                !includes.include?("optional?") && !dependent.build.with?(req)
              elsif req.build?
                !includes.include?("build?")
              end
            end

            reqs = reqs_by_formula.map(&:last)
          else
            deps ||= reject_ignores(f.deps, ignores, includes)
            reqs   = reject_ignores(f.requirements, ignores, includes)
          end

          next true if deps.any? do |dep|
            begin
              dep.to_formula.full_name == ff.full_name
            rescue
              dep.name == ff.name
            end
          end

          reqs.any? { |req| req.name == ff.name }
        rescue FormulaUnavailableError
          # Silently ignore this case as we don't care about things used in
          # taps that aren't currently tapped.
          next
        end
      end
    end
    $stderr.puts if verbose_using_dots

    return if uses.empty?
    puts Formatter.columns(uses.map(&:full_name).sort)
    odie "Missing formulae should not have dependents!" if used_formulae_missing
  end
end
