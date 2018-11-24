# frozen_string_literal: true

module RuboCop
  module RSpec
    # Wrapper for RSpec example groups
    class ExampleGroup < Concept
      # @!method scope_change?(node)
      #
      #   Detect if the node is an example group or shared example
      #
      #   Selectors which indicate that we should stop searching
      #
      def_node_matcher :scope_change?, (
        ExampleGroups::ALL + SharedGroups::ALL + Includes::ALL
      ).block_pattern

      def subjects
        subjects_in_scope(node)
      end

      def examples
        examples_in_scope(node).map(&Example.public_method(:new))
      end

      def hooks
        hooks_in_scope(node).map(&Hook.public_method(:new))
      end

      private

      def subjects_in_scope(node)
        node.each_child_node.flat_map do |child|
          find_subjects(child)
        end
      end

      def find_subjects(node)
        return [] if scope_change?(node)

        if subject?(node)
          [node]
        else
          subjects_in_scope(node)
        end
      end

      def hooks_in_scope(node)
        node.each_child_node.flat_map do |child|
          find_hooks(child)
        end
      end

      def find_hooks(node)
        return [] if scope_change?(node) || example?(node)

        if hook?(node)
          [node]
        else
          hooks_in_scope(node)
        end
      end

      def examples_in_scope(node, &blk)
        node.each_child_node.flat_map do |child|
          find_examples(child, &blk)
        end
      end

      # Recursively search for examples within the current scope
      #
      # Searches node for examples and halts when a scope change is detected
      #
      # @param node [RuboCop::Node] node to recursively search for examples
      #
      # @return [Array<RuboCop::Node>] discovered example nodes
      def find_examples(node)
        return [] if scope_change?(node)

        if example?(node)
          [node]
        else
          examples_in_scope(node)
        end
      end
    end
  end
end
