#:  * `deps` [`--1`] [`-n`] [`--union`] [`--full-name`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] <formulae>:
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
#:
#:  * `deps` `--tree` [<filters>] (<formulae>|`--installed`):
#:    Show dependencies as a tree. When given multiple formula arguments, output
#:    individual trees for every formula.
#:
#:    If `--installed` is passed, output a tree for every installed formula.
#:
#:    The <filters> placeholder is any combination of options `--include-build`,
#:    `--include-optional`, and `--skip-recommended` as documented above.
#:
#:  * `deps` [<filters>] (`--installed`|`--all`):
#:    Show dependencies for installed or all available formulae. Every line of
#:    output starts with the formula name, followed by a colon and all direct
#:    dependencies of that formula.
#:
#:    The <filters> placeholder is any combination of options `--include-build`,
#:    `--include-optional`, and `--skip-recommended` as documented above.

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
      union?: ARGV.include?("--union")
    )

    if mode.installed? && mode.tree?
      puts_deps_tree Formula.installed
    elsif mode.all?
      puts_deps Formula
    elsif mode.tree?
      raise FormulaUnspecifiedError if ARGV.named.empty?
      puts_deps_tree ARGV.formulae
    elsif ARGV.named.empty?
      raise FormulaUnspecifiedError unless mode.installed?
      puts_deps Formula.installed
    else
      all_deps = deps_for_formulae(ARGV.formulae, !ARGV.one?, &(mode.union? ? :| : :&))
      all_deps = all_deps.select(&:installed?) if mode.installed?
      all_deps = if ARGV.include? "--full-name"
        all_deps.map(&:to_formula).map(&:full_name)
      else
        all_deps.map(&:name)
      end.uniq
      all_deps.sort! unless mode.topo_order?
      puts all_deps
    end
  end

  def deps_for_formula(f, recursive = false)
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

    deps + reqs.select(&:default_formula?).map(&:to_dependency)
  end

  def deps_for_formulae(formulae, recursive = false, &block)
    formulae.map { |f| deps_for_formula(f, recursive) }.inject(&block)
  end

  def puts_deps(formulae)
    formulae.each { |f| puts "#{f.full_name}: #{deps_for_formula(f).sort_by(&:name) * " "}" }
  end

  def puts_deps_tree(formulae)
    formulae.each do |f|
      puts "#{f.full_name} (required dependencies)"
      recursive_deps_tree(f, "")
      puts
    end
  end

  def recursive_deps_tree(f, prefix)
    reqs = f.requirements.select(&:default_formula?)
    max = reqs.length - 1
    reqs.each_with_index do |req, i|
      chr = i == max ? "└──" : "├──"
      puts prefix + "#{chr} :#{req.to_dependency.name}"
    end
    deps = f.deps.default
    max = deps.length - 1
    deps.each_with_index do |dep, i|
      chr = i == max ? "└──" : "├──"
      prefix_ext = i == max ? "    " : "│   "
      puts prefix + "#{chr} #{dep.name}"
      recursive_deps_tree(Formulary.factory(dep.name), prefix + prefix_ext)
    end
  end
end
