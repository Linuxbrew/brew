# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Enforces use of string to titleize shared examples.
      #
      # @example
      #   # bad
      #   it_behaves_like :foo_bar_baz
      #   it_should_behave_like :foo_bar_baz
      #   shared_examples :foo_bar_baz
      #   shared_examples_for :foo_bar_baz
      #   include_examples :foo_bar_baz
      #
      #   # good
      #   it_behaves_like 'foo bar baz'
      #   it_should_behave_like 'foo bar baz'
      #   shared_examples 'foo bar baz'
      #   shared_examples_for 'foo bar baz'
      #   include_examples 'foo bar baz'
      #
      class SharedExamples < Cop
        def_node_matcher :shared_examples, <<-PATTERN
          (send
            {(const nil? :RSpec) nil?}
            {#{(SharedGroups::ALL + Includes::ALL).node_pattern}} $sym ...)
        PATTERN

        def on_send(node)
          shared_examples(node) do |ast_node|
            checker = Checker.new(ast_node)
            add_offense(checker.node, message: checker.message)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            checker = Checker.new(node)
            corrector.replace(node.loc.expression, checker.preferred_style)
          end
        end

        # :nodoc:
        class Checker
          MSG = 'Prefer %<prefer>s over `%<current>s` ' \
                'to titleize shared examples.'.freeze

          attr_reader :node
          def initialize(node)
            @node = node
          end

          def message
            format(MSG, prefer: preferred_style, current: symbol.inspect)
          end

          def preferred_style
            string = symbol.to_s.tr('_', ' ')
            wrap_with_single_quotes(string)
          end

          private

          def symbol
            node.value
          end

          def wrap_with_single_quotes(string)
            "'#{string}'"
          end
        end
      end
    end
  end
end
