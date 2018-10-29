module RuboCop
  module Cop
    module RSpec
      # Check that instances are not being stubbed globally.
      #
      # Prefer instance doubles over stubbing any instance of a class
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     before { allow_any_instance_of(MyClass).to receive(:foo) }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     let(:my_instance) { instance_double(MyClass) }
      #
      #     before do
      #       allow(MyClass).to receive(:new).and_return(my_instance)
      #       allow(my_instance).to receive(:foo)
      #     end
      #   end
      class AnyInstance < Cop
        MSG = 'Avoid stubbing using `%<method>s`.'.freeze

        def_node_matcher :disallowed_stub, <<-PATTERN
          (send _ ${:any_instance :allow_any_instance_of :expect_any_instance_of} ...)
        PATTERN

        def on_send(node)
          disallowed_stub(node) do |method|
            add_offense(
              node,
              location: :expression,
              message: format(MSG, method: method)
            )
          end
        end
      end
    end
  end
end
