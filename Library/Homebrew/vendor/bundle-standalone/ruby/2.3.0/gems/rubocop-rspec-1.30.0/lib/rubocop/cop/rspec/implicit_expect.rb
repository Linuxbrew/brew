# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that a consistent implicit expectation style is used.
      #
      # This cop can be configured using the `EnforcedStyle` option
      # and supports the `--auto-gen-config` flag.
      #
      # @example `EnforcedStyle: is_expected`
      #
      #   # bad
      #   it { should be_truthy }
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #
      # @example `EnforcedStyle: should`
      #
      #   # bad
      #   it { is_expected.to be_truthy }
      #
      #   # good
      #   it { should be_truthy }
      #
      class ImplicitExpect < Cop
        include ConfigurableEnforcedStyle

        MSG = 'Prefer `%<good>s` over `%<bad>s`.'.freeze

        def_node_matcher :implicit_expect, <<-PATTERN
          {
            (send nil? ${:should :should_not} ...)
            (send (send nil? $:is_expected) {:to :to_not :not_to} ...)
          }
        PATTERN

        alternatives = {
          'is_expected.to'     => 'should',
          'is_expected.not_to' => 'should_not',
          'is_expected.to_not' => 'should_not'
        }

        ENFORCED_REPLACEMENTS = alternatives.merge(alternatives.invert).freeze

        def on_send(node) # rubocop:disable Metrics/MethodLength
          return unless (source_range = offending_expect(node))

          expectation_source = source_range.source

          if expectation_source.start_with?(style.to_s)
            correct_style_detected
          else
            opposite_style_detected

            add_offense(
              node,
              location: source_range,
              message: offense_message(expectation_source)
            )
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            offense     = offending_expect(node)
            replacement = replacement_source(offense.source)

            corrector.replace(offense, replacement)
          end
        end

        private

        def offending_expect(node)
          case implicit_expect(node)
          when :is_expected
            is_expected_range(node.loc)
          when :should, :should_not
            node.loc.selector
          end
        end

        def is_expected_range(source_map) # rubocop:disable PredicateName
          Parser::Source::Range.new(
            source_map.expression.source_buffer,
            source_map.expression.begin_pos,
            source_map.selector.end_pos
          )
        end

        def offense_message(offending_source)
          format(
            MSG,
            good: replacement_source(offending_source),
            bad:  offending_source
          )
        end

        def replacement_source(offending_source)
          ENFORCED_REPLACEMENTS.fetch(offending_source)
        end
      end
    end
  end
end
