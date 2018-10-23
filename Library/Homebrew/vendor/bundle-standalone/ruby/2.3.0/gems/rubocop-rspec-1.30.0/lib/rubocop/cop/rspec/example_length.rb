# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for long examples.
      #
      # A long example is usually more difficult to understand. Consider
      # extracting out some behaviour, e.g. with a `let` block, or a helper
      # method.
      #
      # @example
      #   # bad
      #   it do
      #     service = described_class.new
      #     more_setup
      #     more_setup
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      #   # good
      #   it do
      #     service = described_class.new
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      class ExampleLength < Cop
        include CodeLength

        MSG = 'Example has too many lines [%<total>d/%<max>d].'.freeze

        def on_block(node)
          return unless example?(node)

          length = code_length(node)

          return unless length > max_length

          add_offense(node, location: :expression, message: message(length))
        end

        private

        def code_length(node)
          node.source.lines[1..-2].count { |line| !irrelevant_line(line) }
        end

        def message(length)
          format(MSG, total: length, max: max_length)
        end
      end
    end
  end
end
