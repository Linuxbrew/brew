module RuboCop
  module Cop
    module RSpec
      # Check for repeated examples within example groups.
      #
      # @example
      #
      #    it 'is valid' do
      #      expect(user).to be_valid
      #    end
      #
      #    it 'validates the user' do
      #      expect(user).to be_valid
      #    end
      #
      class RepeatedExample < Cop
        MSG = "Don't repeat examples within an example group.".freeze

        def on_block(node)
          return unless example_group?(node)

          repeated_examples(node).each do |repeated_example|
            add_offense(repeated_example, location: :expression)
          end
        end

        private

        def repeated_examples(node)
          RuboCop::RSpec::ExampleGroup.new(node)
            .examples
            .group_by { |example| example_signature(example) }
            .values
            .reject(&:one?)
            .flatten
            .map(&:to_node)
        end

        def example_signature(example)
          key_parts = [example.metadata, example.implementation]

          if example.definition.method_name == :its
            key_parts << example.definition.arguments
          end

          key_parts
        end
      end
    end
  end
end
