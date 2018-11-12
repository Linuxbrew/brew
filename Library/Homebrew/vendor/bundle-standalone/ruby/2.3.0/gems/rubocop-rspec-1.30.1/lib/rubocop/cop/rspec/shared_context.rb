# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for proper shared_context and shared_examples usage.
      #
      # If there are no examples defined, use shared_context.
      # If there is no setup defined, use shared_examples.
      #
      # @example
      #   # bad
      #   RSpec.shared_context 'only examples here' do
      #     it 'does x' do
      #     end
      #
      #     it 'does y' do
      #     end
      #   end
      #
      #   # good
      #   RSpec.shared_examples 'only examples here' do
      #     it 'does x' do
      #     end
      #
      #     it 'does y' do
      #     end
      #   end
      #
      # @example
      #   # bad
      #   RSpec.shared_examples 'only setup here' do
      #     subject(:foo) { :bar }
      #
      #     let(:baz) { :bazz }
      #
      #     before do
      #       something
      #     end
      #   end
      #
      #   # good
      #   RSpec.shared_context 'only setup here' do
      #     subject(:foo) { :bar }
      #
      #     let(:baz) { :bazz }
      #
      #     before do
      #       something
      #     end
      #   end
      #
      class SharedContext < Cop
        MSG_EXAMPLES = "Use `shared_examples` when you don't "\
                       'define context.'.freeze

        MSG_CONTEXT  = "Use `shared_context` when you don't "\
                       'define examples.'.freeze

        examples = (Examples::ALL + Includes::EXAMPLES)
        def_node_search :examples?, examples.send_pattern

        context = (Hooks::ALL + Helpers::ALL + Includes::CONTEXT + Subject::ALL)
        def_node_search :context?, context.send_pattern

        def_node_matcher :shared_context, SharedGroups::CONTEXT.block_pattern
        def_node_matcher :shared_example, SharedGroups::EXAMPLES.block_pattern

        def on_block(node)
          context_with_only_examples(node) do
            add_shared_item_offense(node.send_node, MSG_EXAMPLES)
          end

          examples_with_only_context(node) do
            add_shared_item_offense(node.send_node, MSG_CONTEXT)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            context_with_only_examples(node.parent) do
              corrector.replace(node.loc.selector, 'shared_examples')
            end

            examples_with_only_context(node.parent) do
              corrector.replace(node.loc.selector, 'shared_context')
            end
          end
        end

        private

        def context_with_only_examples(node)
          shared_context(node) { yield if examples?(node) && !context?(node) }
        end

        def examples_with_only_context(node)
          shared_example(node) { yield if context?(node) && !examples?(node) }
        end

        def add_shared_item_offense(node, message)
          add_offense(
            node,
            location: :expression,
            message: message
          )
        end
      end
    end
  end
end
