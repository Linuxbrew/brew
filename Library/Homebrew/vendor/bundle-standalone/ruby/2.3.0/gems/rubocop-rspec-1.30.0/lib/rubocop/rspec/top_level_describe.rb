module RuboCop
  module RSpec
    # Helper methods for top level describe cops
    module TopLevelDescribe
      extend NodePattern::Macros

      def_node_matcher :described_constant, <<-PATTERN
        (block $(send _ :describe $(const ...)) (args) $_)
      PATTERN

      def on_send(node)
        return unless respond_to?(:on_top_level_describe)
        return unless top_level_describe?(node)

        on_top_level_describe(node, node.arguments)
      end

      private

      def top_level_describe?(node)
        return false unless node.method_name == :describe

        top_level_nodes.include?(node)
      end

      def top_level_nodes
        nodes = describe_statement_children(root_node)
        # If we have no top level describe statements, we need to check any
        # blocks on the top level (e.g. after a require).
        if nodes.empty?
          nodes = root_node.each_child_node(:block).flat_map do |child|
            describe_statement_children(child)
          end
        end

        nodes
      end

      def root_node
        processed_source.ast
      end

      def single_top_level_describe?
        top_level_nodes.one?
      end

      def describe_statement_children(node)
        node.each_child_node(:send).select do |element|
          element.method_name == :describe
        end
      end
    end
  end
end
