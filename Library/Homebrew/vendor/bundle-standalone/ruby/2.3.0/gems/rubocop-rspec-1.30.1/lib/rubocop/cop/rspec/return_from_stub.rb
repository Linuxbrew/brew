# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style of stub's return setting.
      #
      # Enforces either `and_return` or block-style return in the cases
      # where the returned value is constant. Ignores dynamic returned values
      # are the result would be different
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: block`
      #   # bad
      #   allow(Foo).to receive(:bar).and_return("baz")
      #   expect(Foo).to receive(:bar).and_return("baz")
      #
      #   # good
      #   allow(Foo).to receive(:bar) { "baz" }
      #   expect(Foo).to receive(:bar) { "baz" }
      #   # also good as the returned value is dynamic
      #   allow(Foo).to receive(:bar).and_return(bar.baz)
      #
      # @example `EnforcedStyle: and_return`
      #   # bad
      #   allow(Foo).to receive(:bar) { "baz" }
      #   expect(Foo).to receive(:bar) { "baz" }
      #
      #   # good
      #   allow(Foo).to receive(:bar).and_return("baz")
      #   expect(Foo).to receive(:bar).and_return("baz")
      #   # also good as the returned value is dynamic
      #   allow(Foo).to receive(:bar) { bar.baz }
      #
      class ReturnFromStub < Cop
        include ConfigurableEnforcedStyle

        MSG_AND_RETURN = 'Use `and_return` for static values.'.freeze
        MSG_BLOCK = 'Use block for static values.'.freeze

        def_node_search :contains_stub?, '(send nil? :receive (...))'
        def_node_search :and_return_value, <<-PATTERN
          $(send _ :and_return $(...))
        PATTERN

        def on_send(node)
          return unless contains_stub?(node)
          return unless style == :block

          check_and_return_call(node)
        end

        def on_block(node)
          return unless contains_stub?(node)
          return unless style == :and_return

          check_block_body(node)
        end

        def autocorrect(node)
          if style == :block
            AndReturnCallCorrector.new(node)
          else
            BlockBodyCorrector.new(node)
          end
        end

        private

        def check_and_return_call(node)
          and_return_value(node) do |and_return, args|
            unless dynamic?(args)
              add_offense(
                and_return,
                location: :selector,
                message: MSG_BLOCK
              )
            end
          end
        end

        def check_block_body(block)
          body = block.body
          unless dynamic?(body) # rubocop:disable Style/GuardClause
            add_offense(
              block,
              location: :begin,
              message: MSG_AND_RETURN
            )
          end
        end

        def dynamic?(node)
          node && !node.recursive_literal_or_const?
        end

        # :nodoc:
        class AndReturnCallCorrector
          def initialize(node)
            @node = node
            @receiver = node.receiver
            @arg = node.first_argument
          end

          def call(corrector)
            # Heredoc autocorrection is not yet implemented.
            return if heredoc?

            corrector.replace(range, " { #{replacement} }")
          end

          private

          attr_reader :node, :receiver, :arg

          def heredoc?
            arg.loc.is_a?(Parser::Source::Map::Heredoc)
          end

          def range
            Parser::Source::Range.new(
              node.source_range.source_buffer,
              receiver.source_range.end_pos,
              node.source_range.end_pos
            )
          end

          def replacement
            if hash_without_braces?
              "{ #{arg.source} }"
            else
              arg.source
            end
          end

          def hash_without_braces?
            arg.hash_type? && !arg.braces?
          end
        end

        # :nodoc:
        class BlockBodyCorrector
          def initialize(block)
            @block = block
            @node = block.parent
            @body = block.body || NULL_BLOCK_BODY
          end

          def call(corrector)
            # Heredoc autocorrection is not yet implemented.
            return if heredoc?

            corrector.replace(
              block.loc.expression,
              "#{block.send_node.source}.and_return(#{body.source})"
            )
          end

          private

          attr_reader :node, :block, :body

          def heredoc?
            body.loc.is_a?(Parser::Source::Map::Heredoc)
          end

          NULL_BLOCK_BODY = Struct.new(:loc, :source).new(nil, 'nil')
        end
      end
    end
  end
end
