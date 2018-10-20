module RuboCop
  module Cop
    module RSpec
      # Check for repeated description strings in example groups.
      #
      # @example
      #
      #     # bad
      #     RSpec.describe User do
      #       it 'is valid' do
      #         # ...
      #       end
      #
      #       it 'is valid' do
      #         # ...
      #       end
      #     end
      #
      #     # good
      #     RSpec.describe User do
      #       it 'is valid when first and last name are present' do
      #         # ...
      #       end
      #
      #       it 'is valid when last name only is present' do
      #         # ...
      #       end
      #     end
      #
      class RepeatedDescription < Cop
        MSG = "Don't repeat descriptions within an example group.".freeze

        def on_block(node)
          return unless example_group?(node)

          repeated_descriptions(node).each do |repeated_description|
            add_offense(repeated_description, location: :expression)
          end
        end

        private

        # Select examples in the current scope with repeated description strings
        def repeated_descriptions(node)
          grouped_examples =
            RuboCop::RSpec::ExampleGroup.new(node)
              .examples
              .group_by(&:doc_string)

          grouped_examples
            .select { |description, group| description && group.size > 1 }
            .values
            .flatten
            .map(&:definition)
        end
      end
    end
  end
end
