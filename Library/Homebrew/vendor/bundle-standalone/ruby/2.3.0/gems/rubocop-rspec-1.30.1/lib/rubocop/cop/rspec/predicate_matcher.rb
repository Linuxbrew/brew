module RuboCop
  module Cop
    module RSpec
      # A helper for `inflected` style
      module InflectedHelper
        extend NodePattern::Macros

        MSG_INFLECTED = 'Prefer using `%<matcher_name>s` matcher over ' \
                        '`%<predicate_name>s`.'.freeze

        private

        def check_inflected(node)
          predicate_in_actual?(node) do |predicate|
            add_offense(
              node,
              location: :expression,
              message: message_inflected(predicate)
            )
          end
        end

        def_node_matcher :predicate_in_actual?, <<-PATTERN
          (send
            (send nil? :expect {
              (block $(send !nil? #predicate? ...) ...)
              $(send !nil? #predicate? ...)})
            ${:to :not_to :to_not}
            $#boolean_matcher?)
        PATTERN

        def_node_matcher :be_bool?, <<-PATTERN
          (send nil? {:be :eq :eql :equal} {true false})
        PATTERN

        def_node_matcher :be_boolthy?, <<-PATTERN
          (send nil? {:be_truthy :be_falsey :be_falsy :a_truthy_value :a_falsey_value :a_falsy_value})
        PATTERN

        def boolean_matcher?(node)
          if cop_config['Strict']
            be_boolthy?(node)
          else
            be_bool?(node) || be_boolthy?(node)
          end
        end

        def predicate?(sym)
          sym.to_s.end_with?('?')
        end

        def message_inflected(predicate)
          format(MSG_INFLECTED,
                 predicate_name: predicate.method_name,
                 matcher_name: to_predicate_matcher(predicate.method_name))
        end

        # rubocop:disable Metrics/MethodLength
        def to_predicate_matcher(name)
          case name = name.to_s
          when 'is_a?'
            'be_a'
          when 'instance_of?'
            'be_an_instance_of'
          when 'include?', 'respond_to?'
            name[0..-2]
          when /^has_/
            name.sub('has_', 'have_')[0..-2]
          else
            "be_#{name[0..-2]}"
          end
        end
        # rubocop:enable Metrics/MethodLength

        def autocorrect_inflected(node)
          predicate_in_actual?(node) do |predicate, to, matcher|
            lambda do |corrector|
              remove_predicate(corrector, predicate)
              corrector.replace(node.loc.selector,
                                true?(to, matcher) ? 'to' : 'not_to')
              rewrite_matcher(corrector, predicate, matcher)
            end
          end
        end

        def remove_predicate(corrector, predicate)
          range = range_between(
            predicate.loc.dot.begin_pos,
            predicate.loc.expression.end_pos
          )
          corrector.remove(range)

          block_range = block_loc(predicate)
          corrector.remove(block_range) if block_range
        end

        def rewrite_matcher(corrector, predicate, matcher)
          args = args_loc(predicate).source
          block_loc = block_loc(predicate)
          block = block_loc ? block_loc.source : ''

          corrector.replace(
            matcher.loc.expression,
            to_predicate_matcher(predicate.method_name) + args + block
          )
        end

        def true?(to_symbol, matcher)
          result = case matcher.method_name
                   when :be, :eq
                     matcher.first_argument.true_type?
                   when :be_truthy, :a_truthy_value
                     true
                   when :be_falsey, :be_falsy, :a_falsey_value, :a_falsy_value
                     false
                   end
          to_symbol == :to ? result : !result
        end
      end

      # A helper for `explicit` style
      # rubocop:disable Metrics/ModuleLength
      module ExplicitHelper
        extend NodePattern::Macros

        MSG_EXPLICIT = 'Prefer using `%<predicate_name>s` over ' \
                       '`%<matcher_name>s` matcher.'.freeze
        BUILT_IN_MATCHERS = %w[
          be_truthy be_falsey be_falsy
          have_attributes have_received
          be_between be_within
        ].freeze

        private

        def check_explicit(node) # rubocop:disable Metrics/MethodLength
          predicate_matcher_block?(node) do |_actual, matcher|
            add_offense(
              node,
              location: :expression,
              message: message_explicit(matcher)
            )
            ignore_node(node.children.first)
            return
          end

          return if part_of_ignored_node?(node)

          predicate_matcher?(node) do |_actual, matcher|
            add_offense(
              node,
              location: :expression,
              message: message_explicit(matcher)
            )
          end
        end

        def_node_matcher :predicate_matcher?, <<-PATTERN
          (send
            (send nil? :expect $!nil?)
            {:to :not_to :to_not}
            {$(send nil? #predicate_matcher_name? ...)
              (block $(send nil? #predicate_matcher_name? ...) ...)})
        PATTERN

        def_node_matcher :predicate_matcher_block?, <<-PATTERN
          (block
            (send
              (send nil? :expect $!nil?)
              {:to :not_to :to_not}
              $(send nil? #predicate_matcher_name?))
            ...)
        PATTERN

        def predicate_matcher_name?(name)
          name = name.to_s
          name.start_with?('be_', 'have_') &&
            !BUILT_IN_MATCHERS.include?(name) &&
            !name.end_with?('?')
        end

        def message_explicit(matcher)
          format(MSG_EXPLICIT,
                 predicate_name: to_predicate_method(matcher.method_name),
                 matcher_name: matcher.method_name)
        end

        def autocorrect_explicit(node)
          autocorrect_explicit_send(node) ||
            autocorrect_explicit_block(node)
        end

        def autocorrect_explicit_send(node)
          predicate_matcher?(node) do |actual, matcher|
            corrector_explicit(node, actual, matcher, matcher)
          end
        end

        def autocorrect_explicit_block(node)
          predicate_matcher_block?(node) do |actual, matcher|
            to_node = node.send_node
            corrector_explicit(to_node, actual, matcher, to_node)
          end
        end

        def corrector_explicit(to_node, actual, matcher, block_child)
          lambda do |corrector|
            replacement_matcher = replacement_matcher(to_node)
            corrector.replace(matcher.loc.expression, replacement_matcher)
            move_predicate(corrector, actual, matcher, block_child)
            corrector.replace(to_node.loc.selector, 'to')
          end
        end

        def move_predicate(corrector, actual, matcher, block_child)
          predicate = to_predicate_method(matcher.method_name)
          args = args_loc(matcher).source
          block_loc = block_loc(block_child)
          block = block_loc ? block_loc.source : ''

          corrector.remove(block_loc) if block_loc
          corrector.insert_after(actual.loc.expression,
                                 ".#{predicate}" + args + block)
        end

        # rubocop:disable Metrics/MethodLength
        def to_predicate_method(matcher)
          case matcher = matcher.to_s
          when 'be_a', 'be_an', 'be_a_kind_of', 'a_kind_of', 'be_kind_of'
            'is_a?'
          when 'be_an_instance_of', 'be_instance_of', 'an_instance_of'
            'instance_of?'
          when 'include', 'respond_to'
            matcher + '?'
          when /^have_(.+)/
            "has_#{Regexp.last_match(1)}?"
          else
            matcher[/^be_(.+)/, 1] + '?'
          end
        end
        # rubocop:enable Metrics/MethodLength

        def replacement_matcher(node)
          case [cop_config['Strict'], node.method_name == :to]
          when [true, true]
            'be(true)'
          when [true, false]
            'be(false)'
          when [false, true]
            'be_truthy'
          when [false, false]
            'be_falsey'
          end
        end
      end
      # rubocop:enable Metrics/ModuleLength

      # Prefer using predicate matcher over using predicate method directly.
      #
      # RSpec defines magic matchers for predicate methods.
      # This cop recommends to use the predicate matcher instead of using
      # predicate method directly.
      #
      # @example Strict: true, EnforcedStyle: inflected (default)
      #   # bad
      #   expect(foo.something?).to be_truthy
      #
      #   # good
      #   expect(foo).to be_something
      #
      #   # also good - It checks "true" strictly.
      #   expect(foo).to be(true)
      #
      # @example Strict: false, EnforcedStyle: inflected
      #   # bad
      #   expect(foo.something?).to be_truthy
      #   expect(foo).to be(true)
      #
      #   # good
      #   expect(foo).to be_something
      #
      # @example Strict: true, EnforcedStyle: explicit
      #   # bad
      #   expect(foo).to be_something
      #
      #   # good - the above code is rewritten to it by this cop
      #   expect(foo.something?).to be(true)
      #
      # @example Strict: false, EnforcedStyle: explicit
      #   # bad
      #   expect(foo).to be_something
      #
      #   # good - the above code is rewritten to it by this cop
      #   expect(foo.something?).to be_truthy
      class PredicateMatcher < Cop
        include ConfigurableEnforcedStyle
        include InflectedHelper
        include ExplicitHelper
        include RangeHelp

        def on_send(node)
          case style
          when :inflected
            check_inflected(node)
          when :explicit
            check_explicit(node)
          end
        end

        def on_block(node)
          check_explicit(node) if style == :explicit
        end

        def autocorrect(node)
          case style
          when :inflected
            autocorrect_inflected(node)
          when :explicit
            autocorrect_explicit(node)
          end
        end

        private

        # returns args location with whitespace
        # @example
        #   foo 1, 2
        #      ^^^^^
        def args_loc(send_node)
          range_between(send_node.loc.selector.end_pos,
                        send_node.loc.expression.end_pos)
        end

        # returns block location with whitespace
        # @example
        #   foo { bar }
        #      ^^^^^^^^
        def block_loc(send_node)
          parent = send_node.parent
          return unless parent.block_type?

          range_between(
            send_node.loc.expression.end_pos,
            parent.loc.expression.end_pos
          )
        end
      end
    end
  end
end
