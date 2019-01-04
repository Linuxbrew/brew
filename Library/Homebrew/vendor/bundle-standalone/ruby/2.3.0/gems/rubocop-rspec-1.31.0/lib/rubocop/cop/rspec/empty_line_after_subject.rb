# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after subject block.
      #
      # @example
      #   # bad
      #   subject(:obj) { described_class }
      #   let(:foo) { bar }
      #
      #   # good
      #   subject(:obj) { described_class }
      #
      #   let(:foo) { bar }
      class EmptyLineAfterSubject < Cop
        include RuboCop::RSpec::BlankLineSeparation

        MSG = 'Add empty line after `subject`.'.freeze

        def on_block(node)
          return unless subject?(node) && !in_spec_block?(node)
          return if last_child?(node)

          missing_separating_line(node) do |location|
            add_offense(node, location: location, message: MSG)
          end
        end

        private

        def in_spec_block?(node)
          node.each_ancestor(:block).any? do |ancestor|
            Examples::ALL.include?(ancestor.method_name)
          end
        end
      end
    end
  end
end
