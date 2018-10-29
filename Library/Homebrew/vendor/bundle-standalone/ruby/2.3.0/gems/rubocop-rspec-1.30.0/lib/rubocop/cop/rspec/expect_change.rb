# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style of change matcher.
      #
      # Enforces either passing object and attribute as arguments to the matcher
      # or passing a block that reads the attribute value.
      #
      # This cop can be configured using the `EnforcedStyle` option.
      #
      # @example `EnforcedStyle: block`
      #   # bad
      #   expect(run).to change(Foo, :bar)
      #
      #   # good
      #   expect(run).to change { Foo.bar }
      #
      # @example `EnforcedStyle: method_call`
      #   # bad
      #   expect(run).to change { Foo.bar }
      #   expect(run).to change { foo.baz }
      #
      #   # good
      #   expect(run).to change(Foo, :bar)
      #   expect(run).to change(foo, :baz)
      #   # also good when there are arguments or chained method calls
      #   expect(run).to change { Foo.bar(:count) }
      #   expect(run).to change { user.reload.name }
      #
      class ExpectChange < Cop
        include ConfigurableEnforcedStyle

        MSG_BLOCK = 'Prefer `change(%<obj>s, :%<attr>s)`.'.freeze
        MSG_CALL = 'Prefer `change { %<obj>s.%<attr>s }`.'.freeze

        def_node_matcher :expect_change_with_arguments, <<-PATTERN
          (send nil? :change ({const send} nil? $_) (sym $_))
        PATTERN

        def_node_matcher :expect_change_with_block, <<-PATTERN
          (block
            (send nil? :change)
            (args)
            (send ({const send} nil? $_) $_)
          )
        PATTERN

        def on_send(node)
          return unless style == :block

          expect_change_with_arguments(node) do |receiver, message|
            add_offense(
              node,
              message: format(MSG_CALL, obj: receiver, attr: message)
            )
          end
        end

        def on_block(node)
          return unless style == :method_call

          expect_change_with_block(node) do |receiver, message|
            add_offense(
              node,
              message: format(MSG_BLOCK, obj: receiver, attr: message)
            )
          end
        end

        def autocorrect(node)
          if style == :block
            autocorrect_method_call_to_block(node)
          else
            autocorrect_block_to_method_call(node)
          end
        end

        private

        def autocorrect_method_call_to_block(node)
          lambda do |corrector|
            expect_change_with_arguments(node) do |receiver, message|
              replacement = "change { #{receiver}.#{message} }"
              corrector.replace(node.loc.expression, replacement)
            end
          end
        end

        def autocorrect_block_to_method_call(node)
          lambda do |corrector|
            expect_change_with_block(node) do |receiver, message|
              replacement = "change(#{receiver}, :#{message})"
              corrector.replace(node.loc.expression, replacement)
            end
          end
        end
      end
    end
  end
end
