#:  * `deps` [`--1`] [`-n`] [`--union`] [`--tree`] [`--all`] [`--installed`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] <formulae>:
#:    Show dependencies for <formulae>. When given multiple formula arguments,
#:    show the intersection of dependencies for <formulae>, except when passed
#:    `--tree`, `--all`, or `--installed`.
#:
#:    If `--1` is passed, only show dependencies one level down, instead of
#:    recursing.
#:
#:    If `-n` is passed, show dependencies in topological order.
#:
#:    If `--union` is passed, show the union of dependencies for <formulae>,
#:    instead of the intersection.
#:
#:    If `--tree` is passed, show dependencies as a tree.
#:
#:    If `--all` is passed, show dependencies for all formulae.
#:
#:    If `--installed` is passed, show dependencies for all installed formulae.
#:
#:    By default, `deps` shows required and recommended dependencies for
#:    <formulae>. To include the `:build` type dependencies, pass `--include-build`.
#:    Similarly, pass `--include-optional` to include `:optional` dependencies.
#:    To skip `:recommended` type dependencies, pass `--skip-recommended`.

# encoding: UTF-8
require "formula"
require "ostruct"

module Homebrew
  def deps
    mode = OpenStruct.new(
      :installed?  => ARGV.include?("--installed"),
      :tree?       => ARGV.include?("--tree"),
      :all?        => ARGV.include?("--all"),
      :topo_order? => ARGV.include?("-n"),
      :union?      => ARGV.include?("--union")
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
      all_deps = all_deps.map(&:name).uniq
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
        Dependency.prune if ignores.any? { |ignore| dep.send(ignore) } && !includes.any? { |include| dep.send(include) } && !dependent.build.with?(dep)
      end
      reqs = f.recursive_requirements do |dependent, req|
        Requirement.prune if ignores.any? { |ignore| req.send(ignore) } && !includes.any? { |include| req.send(include) } && !dependent.build.with?(req)
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
