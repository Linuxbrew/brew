# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for any pending or skipped examples.
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     it "should be true"
      #   end
      #
      #   describe MyClass do
      #     it "should be true" do
      #       pending
      #     end
      #   end
      #
      #   describe MyClass do
      #     xit "should be true" do
      #     end
      #   end
      #
      #   # good
      #   describe MyClass do
      #   end
      class Pending < Cop
        MSG = 'Pending spec found.'.freeze

        PENDING_EXAMPLES    = Examples::PENDING + Examples::SKIPPED \
                                + ExampleGroups::SKIPPED
        SKIPPABLE_EXAMPLES  = ExampleGroups::GROUPS + Examples::EXAMPLES
        SKIPPABLE_SELECTORS = SKIPPABLE_EXAMPLES.node_pattern_union

        SKIP_SYMBOL    = s(:sym, :skip)
        PENDING_SYMBOL = s(:sym, :pending)

        def_node_matcher :metadata, <<-PATTERN
          {(send nil? #{SKIPPABLE_SELECTORS} ... (hash $...))
           (send nil? #{SKIPPABLE_SELECTORS} $...)}
        PATTERN

        def_node_matcher :pending_block?, PENDING_EXAMPLES.send_pattern

        def on_send(node)
          return unless pending_block?(node) || skipped_from_metadata?(node)

          add_offense(node, location: :expression)
        end

        private

        def skipped_from_metadata?(node)
          (metadata(node) || []).any? { |n| skip_node?(n) }
        end

        def skip_node?(node)
          if node.respond_to?(:key)
            skip_symbol?(node.key) && node.value.truthy_literal?
          else
            skip_symbol?(node)
          end
        end

        def skip_symbol?(symbol_node)
          [SKIP_SYMBOL, PENDING_SYMBOL].include?(symbol_node)
        end
      end
    end
  end
end
