# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for before/around/after hooks that come after an example.
      #
      # @example
      #   # Bad
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   before { prepare }
      #   after { clean_up }
      #
      #   # Good
      #   before { prepare }
      #   after { clean_up }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      class HooksBeforeExamples < Cop
        include RangeHelp
        include RuboCop::RSpec::FinalEndLocation

        MSG = 'Move `%<hook>s` above the examples in the group.'.freeze

        def_node_matcher :example_or_group?, <<-PATTERN
          {
            #{(Examples::ALL + ExampleGroups::ALL).block_pattern}
            #{Includes::EXAMPLES.send_pattern}
          }
        PATTERN

        def on_block(node)
          return unless example_group_with_body?(node)

          check_hooks(node.body) if multiline_block?(node.body)
        end

        def autocorrect(node)
          lambda do |corrector|
            first_example = find_first_example(node.parent)
            first_example_pos = first_example.loc.expression
            indent = "\n" + ' ' * first_example.loc.column

            corrector.insert_before(first_example_pos, source(node) + indent)
            corrector.remove(node_range_with_surrounding_space(node))
          end
        end

        private

        def multiline_block?(block)
          block.begin_type?
        end

        def check_hooks(node)
          first_example = find_first_example(node)
          return unless first_example

          node.each_child_node do |child|
            next if child.sibling_index < first_example.sibling_index
            next unless hook?(child)

            add_offense(
              child,
              message: format(MSG, hook: child.method_name)
            )
          end
        end

        def find_first_example(node)
          node.children.find { |sibling| example_or_group?(sibling) }
        end

        def node_range_with_surrounding_space(node)
          range = node_range(node)
          range_by_whole_lines(range, include_final_newline: true)
        end

        def source(node)
          node_range(node).source
        end

        def node_range(node)
          range_between(
            node.loc.expression.begin_pos,
            final_end_location(node).end_pos
          )
        end
      end
    end
  end
end
