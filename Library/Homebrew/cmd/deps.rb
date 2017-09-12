#:  * `deps` [`--1`] [`-n`] [`--union`] [`--full-name`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--include-requirements`] <formulae>:
#:    Show dependencies for <formulae>. When given multiple formula arguments,
#:    show the intersection of dependencies for <formulae>.
#:
#:    If `--1` is passed, only show dependencies one level down, instead of
#:    recursing.
#:
#:    If `-n` is passed, show dependencies in topological order.
#:
#:    If `--union` is passed, show the union of dependencies for <formulae>,
#:    instead of the intersection.
#:
#:    If `--full-name` is passed, list dependencies by their full name.
#:
#:    If `--installed` is passed, only list those dependencies that are
#:    currently installed.
#:
#:    By default, `deps` shows required and recommended dependencies for
#:    <formulae>. To include the `:build` type dependencies, pass `--include-build`.
#:    Similarly, pass `--include-optional` to include `:optional` dependencies.
#:    To skip `:recommended` type dependencies, pass `--skip-recommended`.
#:    To include requirements in addition to dependencies, pass `--include-requirements`.
#:
#:  * `deps` `--tree` [`--1`] [<filters>] [`--annotate`] (<formulae>|`--installed`):
#:    Show dependencies as a tree. When given multiple formula arguments, output
#:    individual trees for every formula.
#:
#:    If `--1` is passed, only one level of children is displayed.
#:
#:    If `--installed` is passed, output a tree for every installed formula.
#:
#:    The <filters> placeholder is any combination of options `--include-build`,
#:    `--include-optional`, `--skip-recommended`, and `--include-requirements` as
#:    documented above.
#:
#:    If `--annotate` is passed, the build, optional, and recommended dependencies
#:    are marked as such in the output.
#:
#:  * `deps` [<filters>] (`--installed`|`--all`):
#:    Show dependencies for installed or all available formulae. Every line of
#:    output starts with the formula name, followed by a colon and all direct
#:    dependencies of that formula.
#:
#:    The <filters> placeholder is any combination of options `--include-build`,
#:    `--include-optional`, and `--skip-recommended` as documented above.

# The undocumented `--for-each` option will switch into the mode used by `deps --all`,
# but only list dependencies for specified formula, one specified formula per line.
# This is used for debugging the `--installed`/`--all` display mode.

# encoding: UTF-8

require "formula"
require "ostruct"

module Homebrew
  module_function

  def deps
    mode = OpenStruct.new(
      installed?: ARGV.include?("--installed"),
      tree?: ARGV.include?("--tree"),
      all?: ARGV.include?("--all"),
      topo_order?: ARGV.include?("-n"),
      union?: ARGV.include?("--union"),
      for_each?: ARGV.include?("--for-each"),
    )

    if mode.tree?
      if mode.installed?
        puts_deps_tree Formula.installed, !ARGV.one?
      else
        raise FormulaUnspecifiedError if ARGV.named.empty?
        puts_deps_tree ARGV.formulae, !ARGV.one?
      end
    elsif mode.all?
      puts_deps Formula
    elsif ARGV.named.empty?
      raise FormulaUnspecifiedError unless mode.installed?
      puts_deps Formula.installed
    elsif mode.for_each?
      puts_deps ARGV.formulae
    else
      all_deps = deps_for_formulae(ARGV.formulae, !ARGV.one?, &(mode.union? ? :| : :&))
      all_deps = condense_requirements(all_deps)
      all_deps = all_deps.select(&:installed?) if mode.installed?
      all_deps = all_deps.map(&method(:dep_display_name)).uniq
      all_deps.sort! unless mode.topo_order?
      puts all_deps
    end
  end

  def condense_requirements(deps)
    if ARGV.include?("--include-requirements")
      deps
    else
      deps.map do |dep|
        if dep.is_a? Dependency
          dep
        elsif dep.default_formula?
          dep.to_dependency
        end
      end.compact
    end
  end

  def dep_display_name(dep)
    str = if dep.is_a? Requirement
      if ARGV.include?("--include-requirements")
        if dep.default_formula?
          ":#{dep.display_s} (#{dep_display_name(dep.to_dependency)})"
        else
          ":#{dep.display_s}"
        end
      elsif dep.default_formula?
        dep_display_name(dep.to_dependency)
      else
        # This shouldn't happen, but we'll put something here to help debugging
        "::#{dep.name}"
      end
    else
      ARGV.include?("--full-name") ? dep.to_formula.full_name : dep.name
    end
    if ARGV.include?("--annotate")
      str = "#{str}  [build]" if dep.build?
      str = "#{str}  [optional" if dep.optional?
      str = "#{str}  [recommended]" if dep.recommended?
    end
    str
  end

  def deps_for_formula(f, recursive = false)
    includes = []
    ignores = []
    if ARGV.include?("--include-build")
      includes << "build?"
    else
      ignores << "build?"
    end
    if ARGV.include?("--include-optional")
      includes << "optional?"
    else
      ignores << "optional?"
    end
    ignores << "recommended?" if ARGV.include?("--skip-recommended")

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
        ignores.any? { |ignore| dep.send(ignore) } && includes.none? { |include| dep.send(include) }
      end
      reqs = f.requirements.reject do |req|
        ignores.any? { |ignore| req.send(ignore) } && includes.none? { |include| req.send(include) }
      end
    end

    deps + reqs.to_a
  end

  def deps_for_formulae(formulae, recursive = false, &block)
    formulae.map { |f| deps_for_formula(f, recursive) }.inject(&block)
  end

  def puts_deps(formulae)
    formulae.each do |f|
      deps = deps_for_formula(f)
      deps = condense_requirements(deps)
      deps = deps.sort_by(&:name).map(&method(:dep_display_name))
      puts "#{f.full_name}: #{deps.join(" ")}"
    end
  end

  def puts_deps_tree(formulae, recursive = false)
    formulae.each do |f|
      puts f.full_name
      @dep_stack = []
      recursive_deps_tree(f, "", recursive)
      puts
    end
  end

  def recursive_deps_tree(f, prefix, recursive)
    reqs = f.requirements
    deps = f.deps
    dependables = reqs + deps
    dependables = dependables.reject(&:optional?) unless ARGV.include?("--include-optional")
    dependables = dependables.reject(&:build?) unless ARGV.include?("--include-build")
    dependables = dependables.reject(&:recommended?) if ARGV.include?("--skip-recommended")
    max = dependables.length - 1
    @dep_stack.push f.name
    dependables.each_with_index do |dep, i|
      next if !ARGV.include?("--include-requirements") && dep.is_a?(Requirement) && !dep.default_formula?
      tree_lines = if i == max
        "└──"
      else
        "├──"
      end
      display_s = "#{tree_lines} #{dep_display_name(dep)}"
      is_circular = @dep_stack.include?(dep.name)
      display_s = "#{display_s} (CIRCULAR DEPENDENCY)" if is_circular
      puts "#{prefix}#{display_s}"
      next if !recursive || is_circular
      prefix_addition = if i == max
        "    "
      else
        "│   "
      end
      if dep.is_a?(Requirement) && dep.default_formula?
        recursive_deps_tree(Formulary.factory(dep.to_dependency.name), prefix + prefix_addition, true)
      end
      if dep.is_a? Dependency
        recursive_deps_tree(Formulary.factory(dep.name), prefix + prefix_addition, true)
      end
    end
    @dep_stack.pop
  end
end
