# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # Checks for create_list usage.
        #
        # This cop can be configured using the `EnforcedStyle` option
        #
        # @example `EnforcedStyle: create_list`
        #   # bad
        #   3.times { create :user }
        #
        #   # good
        #   create_list :user, 3
        #
        #   # good
        #   3.times { |n| create :user, created_at: n.months.ago }
        #
        # @example `EnforcedStyle: n_times`
        #   # bad
        #   create_list :user, 3
        #
        #   # good
        #   3.times { create :user }
        class CreateList < Cop
          include ConfigurableEnforcedStyle

          MSG_CREATE_LIST = 'Prefer create_list.'.freeze
          MSG_N_TIMES = 'Prefer %<number>s.times.'.freeze

          def_node_matcher :n_times_block_without_arg?, <<-PATTERN
            (block
              (send (int _) :times)
              (args)
              ...
            )
          PATTERN

          def_node_matcher :factory_call, <<-PATTERN
            (send ${(const nil? {:FactoryGirl :FactoryBot}) nil?} :create (sym $_) $...)
          PATTERN

          def_node_matcher :factory_list_call, <<-PATTERN
            (send ${(const nil? {:FactoryGirl :FactoryBot}) nil?} :create_list (sym $_) (int $_) $...)
          PATTERN

          def on_block(node)
            return unless style == :create_list
            return unless n_times_block_without_arg?(node)
            return unless contains_only_factory?(node.body)

            add_offense(node.send_node,
                        location: :expression, message: MSG_CREATE_LIST)
          end

          def on_send(node)
            return unless style == :n_times

            factory_list_call(node) do |_receiver, _factory, count, _|
              add_offense(
                node,
                location: :selector,
                message: format(MSG_N_TIMES, number: count)
              )
            end
          end

          def autocorrect(node)
            if style == :create_list
              autocorrect_n_times_to_create_list(node)
            else
              autocorrect_create_list_to_n_times(node)
            end
          end

          private

          def contains_only_factory?(node)
            if node.block_type?
              factory_call(node.send_node)
            else
              factory_call(node)
            end
          end

          def autocorrect_n_times_to_create_list(node)
            block = node.parent
            count = block.receiver.source
            replacement = factory_call_replacement(block.body, count)

            lambda do |corrector|
              corrector.replace(block.loc.expression, replacement)
            end
          end

          def autocorrect_create_list_to_n_times(node)
            replacement = generate_n_times_block(node)
            lambda do |corrector|
              corrector.replace(node.loc.expression, replacement)
            end
          end

          def generate_n_times_block(node)
            receiver, factory, count, options = *factory_list_call(node)

            arguments = ":#{factory}"
            options = build_options_string(options)
            arguments += ", #{options}" unless options.empty?

            replacement = format_receiver(receiver)
            replacement += format_method_call(node, 'create', arguments)
            "#{count}.times { #{replacement} }"
          end

          def factory_call_replacement(body, count)
            receiver, factory, options = *factory_call(body)

            arguments = ":#{factory}, #{count}"
            options = build_options_string(options)
            arguments += ", #{options}" unless options.empty?

            replacement = format_receiver(receiver)
            replacement += format_method_call(body, 'create_list', arguments)
            replacement
          end

          def build_options_string(options)
            options.map(&:source).join(', ')
          end

          def format_method_call(node, method, arguments)
            if node.parenthesized?
              "#{method}(#{arguments})"
            else
              "#{method} #{arguments}"
            end
          end

          def format_receiver(receiver)
            return '' unless receiver

            "#{receiver.source}."
          end
        end
      end
    end
  end
end
