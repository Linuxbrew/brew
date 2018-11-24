module RuboCop
  module Cop
    module RSpec
      # Prefer `not_to receive(...)` over `receive(...).never`.
      #
      # @example
      #
      #     # bad
      #     expect(foo).to receive(:bar).never
      #
      #     # good
      #     expect(foo).not_to receive(:bar)
      #
      class ReceiveNever < Cop
        include RangeHelp

        MSG = 'Use `not_to receive` instead of `never`.'.freeze

        def_node_search :method_on_stub?, '(send nil? :receive ...)'

        def on_send(node)
          return unless node.method_name == :never && method_on_stub?(node)

          add_offense(
            node,
            location: :selector
          )
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.parent.loc.selector, 'not_to')
            range = range_between(
              node.loc.dot.begin_pos,
              node.loc.selector.end_pos
            )
            corrector.remove(range)
          end
        end
      end
    end
  end
end
