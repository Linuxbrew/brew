# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after hook blocks.
      #
      # @example
      #   # bad
      #   before { do_something }
      #   it { does_something }
      #
      #   # bad
      #   after { do_something }
      #   it { does_something }
      #
      #   # bad
      #   around { |test| test.run }
      #   it { does_something }
      #
      #   # good
      #   before { do_something }
      #
      #   it { does_something }
      #
      #   # good
      #   after { do_something }
      #
      #   it { does_something }
      #
      #   # good
      #   around { |test| test.run }
      #
      #   it { does_something }
      #
      class EmptyLineAfterHook < Cop
        include RuboCop::RSpec::BlankLineSeparation

        MSG = 'Add an empty line after `%<hook>s`.'.freeze

        def on_block(node)
          return unless hook?(node)
          return if last_child?(node)

          missing_separating_line(node) do |location|
            add_offense(
              node,
              location: location,
              message: format(MSG, hook: node.method_name)
            )
          end
        end
      end
    end
  end
end
