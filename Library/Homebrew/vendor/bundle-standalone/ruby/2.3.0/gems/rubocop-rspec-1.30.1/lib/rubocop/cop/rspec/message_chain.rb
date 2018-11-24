module RuboCop
  module Cop
    module RSpec
      # Check that chains of messages are not being stubbed.
      #
      # @example
      #   # bad
      #   allow(foo).to receive_message_chain(:bar, :baz).and_return(42)
      #
      #   # better
      #   thing = Thing.new(baz: 42)
      #   allow(foo).to receive(bar: thing)
      #
      class MessageChain < Cop
        MSG = 'Avoid stubbing using `%<method>s`.'.freeze

        def_node_matcher :message_chain, <<-PATTERN
          (send _ {:receive_message_chain :stub_chain} ...)
        PATTERN

        def on_send(node)
          message_chain(node) { add_offense(node, location: :selector) }
        end

        def message(node)
          format(MSG, method: node.method_name)
        end
      end
    end
  end
end
