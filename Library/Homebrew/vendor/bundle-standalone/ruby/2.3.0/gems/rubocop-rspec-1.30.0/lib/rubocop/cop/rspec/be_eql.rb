module RuboCop
  module Cop
    module RSpec
      # Check for expectations where `be(...)` can replace `eql(...)`.
      #
      # The `be` matcher compares by identity while the `eql` matcher
      # compares using `eql?`. Integers, floats, booleans, symbols, and nil
      # can be compared by identity and therefore the `be` matcher is
      # preferable as it is a more strict test.
      #
      # @example
      #
      #   # bad
      #   expect(foo).to eql(1)
      #   expect(foo).to eql(1.0)
      #   expect(foo).to eql(true)
      #   expect(foo).to eql(false)
      #   expect(foo).to eql(:bar)
      #   expect(foo).to eql(nil)
      #
      #   # good
      #   expect(foo).to be(1)
      #   expect(foo).to be(1.0)
      #   expect(foo).to be(true)
      #   expect(foo).to be(false)
      #   expect(foo).to be(:bar)
      #   expect(foo).to be(nil)
      #
      # This cop only looks for instances of `expect(...).to eql(...)`. We
      # do not check `to_not` or `not_to` since `!eql?` is more strict
      # than `!equal?`. We also do not try to flag `eq` because if
      # `a == b`, and `b` is comparable by identity, `a` is still not
      # necessarily the same type as `b` since the `#==` operator can
      # coerce objects for comparison.
      #
      class BeEql < Cop
        MSG = 'Prefer `be` over `eql`.'.freeze

        def_node_matcher :eql_type_with_identity, <<-PATTERN
          (send _ :to $(send nil? :eql {true false int float sym nil_type?}))
        PATTERN

        def on_send(node)
          eql_type_with_identity(node) do |eql|
            add_offense(eql, location: :selector)
          end
        end

        def autocorrect(node)
          ->(corrector) { corrector.replace(node.loc.selector, 'be') }
        end
      end
    end
  end
end
