require "delegate"

class Dependencies < DelegateClass(Array)
  def initialize(*args)
    super(args)
  end

  alias eql? ==

  def optional
    select(&:optional?)
  end

  def recommended
    select(&:recommended?)
  end

  def build
    select(&:build?)
  end

  def required
    select(&:required?)
  end

  def default
    build + required + recommended
  end

  def inspect
    "#<#{self.class.name}: #{to_a}>"
  end
end

class Requirements < DelegateClass(Set)
  def initialize(*args)
    super(Set.new(args))
  end

  def <<(other)
    if other.is_a?(Comparable)
      grep(other.class) do |req|
        return self if req > other

        delete(req)
      end
    end
    super
    self
  end

  def inspect
    "#<#{self.class.name}: {#{to_a.join(", ")}}>"
  end
end

module Homebrew
  module_function

  def argv_includes_ignores(argv)
    includes = []
    ignores = []

    if argv.include? "--include-build"
      includes << "build?"
    else
      ignores << "build?"
    end

    if argv.include? "--include-test"
      includes << "test?"
    else
      ignores << "test?"
    end

    if argv.include? "--include-optional"
      includes << "optional?"
    else
      ignores << "optional?"
    end

    ignores << "recommended?" if ARGV.include? "--skip-recommended"

    [includes, ignores]
  end

  def recursive_includes(klass, formula, includes, ignores)
    type = if klass == Dependency
      :dependencies
    elsif klass == Requirement
      :requirements
    else
      raise ArgumentError, "Invalid class argument: #{klass}"
    end

    formula.send("recursive_#{type}") do |dependent, dep|
      if dep.recommended?
        if ignores.include?("recommended?") || dependent.build.without?(dep)
          klass.prune
        end
      elsif dep.test?
        if includes.include?("test?")
          if type == :dependencies
            Dependency.keep_but_prune_recursive_deps
          end
        else
          klass.prune
        end
      elsif dep.optional?
        if !includes.include?("optional?") && !dependent.build.with?(dep)
          klass.prune
        end
      elsif dep.build?
        klass.prune unless includes.include?("build?")
      end

      # If a tap isn't installed, we can't find the dependencies of one
      # its formulae, and an exception will be thrown if we try.
      if type == :dependencies &&
         dep.is_a?(TapDependency) &&
         !dep.tap.installed?
        Dependency.keep_but_prune_recursive_deps
      end
    end
  end

  def reject_ignores(dependables, ignores, includes)
    dependables.reject do |dep|
      next false unless ignores.any? { |ignore| dep.send(ignore) }

      includes.none? { |include| dep.send(include) }
    end
  end
end
