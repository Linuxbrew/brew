# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Avoid describing symbols.
      #
      # @example
      #   # bad
      #   describe :my_method do
      #     # ...
      #   end
      #
      #   # good
      #   describe '#my_method' do
      #     # ...
      #   end
      #
      # @see https://github.com/rspec/rspec-core/issues/1610
      class DescribeSymbol < Cop
        MSG = 'Avoid describing symbols.'.freeze

        def_node_matcher :describe_symbol?, <<-PATTERN
          (send {(const nil? :RSpec) nil?} :describe $sym ...)
        PATTERN

        def on_send(node)
          describe_symbol?(node) do |match|
            add_offense(match, location: :expression)
          end
        end
      end
    end
  end
end
