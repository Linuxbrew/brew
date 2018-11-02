# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that the second argument to `describe` specifies a method.
      #
      # @example
      #   # bad
      #   describe MyClass, 'do something' do
      #   end
      #
      #   # good
      #   describe MyClass, '#my_instance_method' do
      #   end
      #
      #   describe MyClass, '.my_class_method' do
      #   end
      class DescribeMethod < Cop
        include RuboCop::RSpec::TopLevelDescribe
        include RuboCop::RSpec::Util

        MSG = 'The second argument to describe should be the method '\
              "being tested. '#instance' or '.class'.".freeze

        def on_top_level_describe(_node, (_, second_arg))
          return unless second_arg && second_arg.str_type?
          return if second_arg.str_content.start_with?('#', '.')

          add_offense(second_arg, location: :expression)
        end
      end
    end
  end
end
