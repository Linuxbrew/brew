module RuboCop
  module Cop
    module RSpec
      # Check for `once` and `twice` receive counts matchers usage.
      #
      # @example
      #
      #     # bad
      #     expect(foo).to receive(:bar).exactly(1).times
      #     expect(foo).to receive(:bar).exactly(2).times
      #     expect(foo).to receive(:bar).at_least(1).times
      #     expect(foo).to receive(:bar).at_least(2).times
      #     expect(foo).to receive(:bar).at_most(1).times
      #     expect(foo).to receive(:bar).at_most(2).times
      #
      #     # good
      #     expect(foo).to receive(:bar).once
      #     expect(foo).to receive(:bar).twice
      #     expect(foo).to receive(:bar).at_least(:once)
      #     expect(foo).to receive(:bar).at_least(:twice)
      #     expect(foo).to receive(:bar).at_most(:once)
      #     expect(foo).to receive(:bar).at_most(:twice).times
      #
      class ReceiveCounts < Cop
        include RangeHelp

        MSG = 'Use `%<alternative>s` instead of `%<original>s`.'.freeze

        def_node_matcher :receive_counts, <<-PATTERN
          (send $(send _ {:exactly :at_least :at_most} (int {1 2})) :times)
        PATTERN

        def on_send(node)
          receive_counts(node) do |offending_node|
            offending_range = range(node, offending_node)

            add_offense(
              offending_node,
              message: message_for(offending_node, offending_range.source),
              location: offending_range
            )
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            replacement = matcher_for(
              node.method_name,
              node.first_argument.source.to_i
            )
            corrector.replace(
              range(node.parent, node),
              replacement
            )
          end
        end

        private

        def message_for(node, source)
          alternative = matcher_for(
            node.method_name,
            node.first_argument.source.to_i
          )
          format(MSG, alternative: alternative, original: source)
        end

        def matcher_for(method, count)
          matcher = count == 1 ? 'once' : 'twice'
          if method == :exactly
            ".#{matcher}"
          else
            ".#{method}(:#{matcher})"
          end
        end

        def range(node, offending_node)
          range_between(
            offending_node.loc.dot.begin_pos,
            node.loc.expression.end_pos
          )
        end
      end
    end
  end
end
