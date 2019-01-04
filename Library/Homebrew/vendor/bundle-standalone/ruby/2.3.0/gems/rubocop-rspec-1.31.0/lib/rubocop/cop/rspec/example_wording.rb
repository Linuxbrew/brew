# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for common mistakes in example descriptions.
      #
      # This cop will correct docstrings that begin with 'should' and 'it'.
      #
      # @see http://betterspecs.org/#should
      #
      # The autocorrect is experimental - use with care! It can be configured
      # with CustomTransform (e.g. have => has) and IgnoredWords (e.g. only).
      #
      # @example
      #   # bad
      #   it 'should find nothing' do
      #   end
      #
      #   # good
      #   it 'finds nothing' do
      #   end
      #
      # @example
      #   # bad
      #   it 'it does things' do
      #   end
      #
      #   # good
      #   it 'does things' do
      #   end
      class ExampleWording < Cop
        MSG_SHOULD = 'Do not use should when describing your tests.'.freeze
        MSG_IT     = "Do not repeat 'it' when describing your tests.".freeze

        SHOULD_PREFIX = /\Ashould(?:n't)?\b/i.freeze
        IT_PREFIX     = /\Ait /i.freeze

        def_node_matcher(
          :it_description,
          '(block (send _ :it $(str $_) ...) ...)'
        )

        def on_block(node)
          it_description(node) do |description_node, message|
            if message =~ SHOULD_PREFIX
              add_wording_offense(description_node, MSG_SHOULD)
            elsif message =~ IT_PREFIX
              add_wording_offense(description_node, MSG_IT)
            end
          end
        end

        def autocorrect(range)
          ->(corrector) { corrector.replace(range, replacement_text(range)) }
        end

        private

        def add_wording_offense(node, message)
          expr = node.loc.expression

          docstring =
            Parser::Source::Range.new(
              expr.source_buffer,
              expr.begin_pos + 1,
              expr.end_pos - 1
            )

          add_offense(docstring, location: docstring, message: message)
        end

        def replacement_text(range)
          text = range.source

          if text =~ SHOULD_PREFIX
            RuboCop::RSpec::Wording.new(
              text,
              ignore:  ignored_words,
              replace: custom_transform
            ).rewrite
          else
            text.sub(IT_PREFIX, '')
          end
        end

        def custom_transform
          cop_config.fetch('CustomTransform', {})
        end

        def ignored_words
          cop_config.fetch('IgnoredWords', [])
        end
      end
    end
  end
end
