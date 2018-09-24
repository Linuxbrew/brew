require "delegate"

require "cask/topological_hash"

module Cask
  class CaskDependencies < DelegateClass(Array)
    attr_reader :cask, :graph

    def initialize(cask)
      @cask = cask
      @graph = graph_dependencies
      super(sort)
    end

    private

    def graph_dependencies(cask = self.cask, acc = TopologicalHash.new)
      return acc if acc.key?(cask)

      deps = cask.depends_on.cask.map(&CaskLoader.public_method(:load))
      acc[cask] = deps
      deps.each do |dep|
        graph_dependencies(dep, acc)
      end
      acc
    end

    def sort
      raise CaskSelfReferencingDependencyError, cask.token if graph[cask].include?(cask)

      graph.tsort - [cask]
    rescue TSort::Cyclic
      strongly_connected_components = graph.strongly_connected_components.sort_by(&:count)
      cyclic_dependencies = strongly_connected_components.last - [cask]
      raise CaskCyclicDependencyError.new(cask.token, cyclic_dependencies.join(", "))
    end
  end
end
