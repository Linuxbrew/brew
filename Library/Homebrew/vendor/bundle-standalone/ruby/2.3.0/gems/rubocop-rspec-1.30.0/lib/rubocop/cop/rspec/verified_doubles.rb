# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer using verifying doubles over normal doubles.
      #
      # @see https://relishapp.com/rspec/rspec-mocks/docs/verifying-doubles
      #
      # @example
      #   # bad
      #   let(:foo) do
      #     double(method_name: 'returned value')
      #   end
      #
      #   # bad
      #   let(:foo) do
      #     double("ClassName", method_name: 'returned value')
      #   end
      #
      #   # good
      #   let(:foo) do
      #     instance_double("ClassName", method_name: 'returned value')
      #   end
      class VerifiedDoubles < Cop
        MSG = 'Prefer using verifying doubles over normal doubles.'.freeze

        def_node_matcher :unverified_double, <<-PATTERN
          {(send nil? {:double :spy} $...)}
        PATTERN

        def on_send(node)
          unverified_double(node) do |name, *_args|
            return if name.nil? && cop_config['IgnoreNameless']
            return if symbol?(name) && cop_config['IgnoreSymbolicNames']

            add_offense(node, location: :expression)
          end
        end

        private

        def symbol?(name)
          name && name.sym_type?
        end
      end
    end
  end
end
