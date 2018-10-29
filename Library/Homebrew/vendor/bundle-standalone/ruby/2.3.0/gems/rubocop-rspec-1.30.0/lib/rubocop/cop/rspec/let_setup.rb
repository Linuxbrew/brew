# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks unreferenced `let!` calls being used for test setup.
      #
      # @example
      #   # Bad
      #   let!(:my_widget) { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # Good
      #   it 'counts widgets' do
      #     create(:widget)
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # Good
      #   before { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      class LetSetup < Cop
        include RuboCop::RSpec::TopLevelDescribe

        MSG = 'Do not use `let!` for test setup.'.freeze

        def_node_search :let_bang, <<-PATTERN
          (block $(send nil? :let! (sym $_)) args ...)
        PATTERN

        def_node_search :method_called?, '(send nil? %)'

        def on_block(node)
          return unless example_group?(node)

          unused_let_bang(node) do |let|
            add_offense(let, location: :expression)
          end
        end

        private

        def unused_let_bang(node)
          let_bang(node) do |method_send, method_name|
            yield(method_send) unless method_called?(node, method_name)
          end
        end
      end
    end
  end
end
