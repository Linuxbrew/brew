# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after the last let block.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #   let(:something) { other }
      #   it { does_something }
      #
      #   # good
      #   let(:foo) { bar }
      #   let(:something) { other }
      #
      #   it { does_something }
      class EmptyLineAfterFinalLet < Cop
        include RuboCop::RSpec::BlankLineSeparation

        MSG = 'Add an empty line after the last `let` block.'.freeze

        def on_block(node)
          return unless example_group_with_body?(node)

          latest_let = node.body.child_nodes.select { |child| let?(child) }.last

          return if latest_let.nil?
          return if last_child?(latest_let)

          missing_separating_line(latest_let) do |location|
            add_offense(latest_let, location: location)
          end
        end
      end
    end
  end
end
