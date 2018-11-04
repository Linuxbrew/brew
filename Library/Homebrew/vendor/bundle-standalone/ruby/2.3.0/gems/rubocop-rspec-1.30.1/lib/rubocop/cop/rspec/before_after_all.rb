# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that before/after(:all) isn't being used.
      #
      # @example
      #   # bad
      #   #
      #   # Faster but risk of state leaking between examples
      #   #
      #   describe MyClass do
      #     before(:all) { Widget.create }
      #     after(:all) { Widget.delete_all }
      #   end
      #
      #   # good
      #   #
      #   # Slower but examples are properly isolated
      #   #
      #   describe MyClass do
      #     before(:each) { Widget.create }
      #     after(:each) { Widget.delete_all }
      #   end
      class BeforeAfterAll < Cop
        MSG = 'Beware of using `%<hook>s` as it may cause state to leak '\
              'between tests. If you are using `rspec-rails`, and '\
              '`use_transactional_fixtures` is enabled, then records created '\
              'in `%<hook>s` are not automatically rolled back.'.freeze

        def_node_matcher :before_or_after_all, <<-PATTERN
          $(send _ {:before :after} (sym {:all :context}))
        PATTERN

        def on_send(node)
          before_or_after_all(node) do |hook|
            add_offense(
              node,
              location: :expression,
              message: format(MSG, hook: hook.source)
            )
          end
        end
      end
    end
  end
end
