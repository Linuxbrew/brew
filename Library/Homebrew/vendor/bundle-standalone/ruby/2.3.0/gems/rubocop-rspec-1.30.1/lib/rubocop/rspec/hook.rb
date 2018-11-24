# frozen_string_literal: true

module RuboCop
  module RSpec
    # Wrapper for RSpec hook
    class Hook < Concept
      STANDARDIZED_SCOPES = %i[each context suite].freeze
      private_constant(:STANDARDIZED_SCOPES)

      def name
        node.method_name
      end

      def knowable_scope?
        return true unless scope_argument

        scope_argument.sym_type?
      end

      def valid_scope?
        STANDARDIZED_SCOPES.include?(scope)
      end

      def example?
        scope.equal?(:each)
      end

      def scope
        case scope_name
        when nil, :each, :example then :each
        when :context, :all       then :context
        when :suite               then :suite
        else
          scope_name
        end
      end

      private

      def scope_name
        scope_argument.to_a.first
      end

      def scope_argument
        node.send_node.first_argument
      end
    end
  end
end
