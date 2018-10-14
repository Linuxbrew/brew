# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that the first argument to an example group is not empty.
      #
      # @example
      #   # bad
      #   describe do
      #   end
      #
      #   RSpec.describe do
      #   end
      #
      #   # good
      #   describe TestedClass do
      #   end
      #
      #   describe "A feature example" do
      #   end
      class MissingExampleGroupArgument < Cop
        MSG = 'The first argument to `%<method>s` should not be empty.'.freeze

        def on_block(node)
          return unless example_group?(node)
          return if node.send_node.arguments?

          add_offense(node, location: :expression,
                            message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
