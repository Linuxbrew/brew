# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks void `expect()`.
      #
      # @example
      #   # bad
      #   expect(something)
      #
      #   # good
      #   expect(something).to be(1)
      class VoidExpect < Cop
        MSG = 'Do not use `expect()` without `.to` or `.not_to`. ' \
              'Chain the methods or remove it.'.freeze

        def_node_matcher :expect?, <<-PATTERN
          (send nil? :expect ...)
        PATTERN

        def_node_matcher :expect_block?, <<-PATTERN
          (block #expect? (args) _body)
        PATTERN

        def on_send(node)
          return unless expect?(node)

          check_expect(node)
        end

        def on_block(node)
          return unless expect_block?(node)

          check_expect(node)
        end

        private

        def check_expect(node)
          return unless void?(node)

          add_offense(node, location: :expression)
        end

        def void?(expect)
          parent = expect.parent
          return true unless parent
          return true if parent.begin_type?
          return true if parent.block_type? && parent.body == expect
        end
      end
    end
  end
end
