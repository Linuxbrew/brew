# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # Always declare attribute values as blocks.
        #
        # @example
        #   # bad
        #   kind [:active, :rejected].sample
        #
        #   # good
        #   kind { [:active, :rejected].sample }
        #
        #   # bad
        #   closed_at 1.day.from_now
        #
        #   # good
        #   closed_at { 1.day.from_now }
        #
        #   # bad
        #   count 1
        #
        #   # good
        #   count { 1 }
        class AttributeDefinedStatically < Cop
          MSG = 'Use a block to declare attribute values.'.freeze

          ATTRIBUTE_DEFINING_METHODS = %i[factory trait transient ignore].freeze

          UNPROXIED_METHODS = %i[
            __send__
            __id__
            nil?
            send
            object_id
            extend
            instance_eval
            initialize
            block_given?
            raise
            caller
            method
          ].freeze

          DEFINITION_PROXY_METHODS = %i[
            add_attribute
            after
            association
            before
            callback
            ignore
            initialize_with
            sequence
            skip_create
            to_create
          ].freeze

          RESERVED_METHODS =
            DEFINITION_PROXY_METHODS +
            UNPROXIED_METHODS +
            ATTRIBUTE_DEFINING_METHODS

          def_node_matcher :value_matcher, <<-PATTERN
            (send {self nil?} !#reserved_method? $...)
          PATTERN

          def_node_search :factory_attributes, <<-PATTERN
            (block (send nil? #attribute_defining_method? ...) _ { (begin $...) $(send ...) } )
          PATTERN

          def on_block(node)
            factory_attributes(node).to_a.flatten.each do |attribute|
              next if proc?(attribute) || association?(attribute)

              add_offense(attribute, location: :expression)
            end
          end

          def autocorrect(node)
            if node.parenthesized?
              autocorrect_replacing_parens(node)
            else
              autocorrect_without_parens(node)
            end
          end

          private

          def proc?(attribute)
            value_matcher(attribute).to_a.all?(&:block_pass_type?)
          end

          def association?(attribute)
            argument = attribute.first_argument
            argument.hash_type? && factory_key?(argument)
          end

          def factory_key?(hash_node)
            hash_node.keys.any? { |key| key.sym_type? && key.value == :factory }
          end

          def autocorrect_replacing_parens(node)
            left_braces, right_braces = braces(node)

            lambda do |corrector|
              corrector.replace(node.location.begin, ' ' + left_braces)
              corrector.replace(node.location.end, right_braces)
            end
          end

          def autocorrect_without_parens(node)
            left_braces, right_braces = braces(node)

            lambda do |corrector|
              argument = node.first_argument
              expression = argument.location.expression
              corrector.insert_before(expression, left_braces)
              corrector.insert_after(expression, right_braces)
            end
          end

          def braces(node)
            if value_hash_without_braces?(node.first_argument)
              ['{ { ', ' } }']
            else
              ['{ ', ' }']
            end
          end

          def value_hash_without_braces?(node)
            node.hash_type? && !node.braces?
          end

          def reserved_method?(method_name)
            RESERVED_METHODS.include?(method_name)
          end

          def attribute_defining_method?(method_name)
            ATTRIBUTE_DEFINING_METHODS.include?(method_name)
          end
        end
      end
    end
  end
end
