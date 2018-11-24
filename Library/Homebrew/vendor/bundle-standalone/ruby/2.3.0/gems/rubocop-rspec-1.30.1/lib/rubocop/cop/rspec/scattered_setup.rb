# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for setup scattered across multiple hooks in an example group.
      #
      # Unify `before`, `after`, and `around` hooks when possible.
      #
      # @example
      #   # bad
      #   describe Foo do
      #     before { setup1 }
      #     before { setup2 }
      #   end
      #
      #   # good
      #   describe Foo do
      #     before do
      #       setup1
      #       setup2
      #     end
      #   end
      #
      class ScatteredSetup < Cop
        MSG = 'Do not define multiple hooks in the same example group.'.freeze

        def on_block(node)
          return unless example_group?(node)

          analyzable_hooks(node).each do |repeated_hook|
            add_offense(repeated_hook, location: :expression)
          end
        end

        def analyzable_hooks(node)
          RuboCop::RSpec::ExampleGroup.new(node)
            .hooks
            .select { |hook| hook.knowable_scope? && hook.valid_scope? }
            .group_by { |hook| [hook.name, hook.scope] }
            .values
            .reject(&:one?)
            .flatten
            .map(&:to_node)
        end
      end
    end
  end
end
