module RuboCop
  module Cop
    module RSpec
      # Checks invalid usage for predicate matcher.
      #
      # Predicate matcher does not need a question.
      # This cop checks an unnecessary question in predicate matcher.
      #
      # @example
      #
      #   # bad
      #   expect(foo).to be_something?
      #
      #   # good
      #   expect(foo).to be_something
      class InvalidPredicateMatcher < Cop
        MSG = 'Omit `?` from `%<matcher>s`.'.freeze

        def_node_matcher :invalid_predicate_matcher?, <<-PATTERN
          (send (send nil? :expect ...) {:to :not_to :to_not} $(send nil? #predicate?))
        PATTERN

        def on_send(node)
          invalid_predicate_matcher?(node) do |predicate|
            add_offense(predicate, location: :expression)
          end
        end

        private

        def predicate?(name)
          name = name.to_s
          name.start_with?('be_', 'have_') && name.end_with?('?')
        end

        def message(predicate)
          format(MSG, matcher: predicate.method_name)
        end
      end
    end
  end
end
