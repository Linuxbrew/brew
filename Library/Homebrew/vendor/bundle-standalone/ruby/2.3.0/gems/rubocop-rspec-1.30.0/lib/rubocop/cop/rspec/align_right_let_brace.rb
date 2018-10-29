# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that right braces for adjacent single line lets are aligned.
      #
      # @example
      #
      #     # bad
      #     let(:foobar) { blahblah }
      #     let(:baz)    { bar }
      #     let(:a)      { b }
      #
      #     # good
      #     let(:foobar) { blahblah }
      #     let(:baz)    { bar      }
      #     let(:a)      { b        }
      #
      class AlignRightLetBrace < Cop
        MSG = 'Align right let brace'.freeze

        def self.autocorrect_incompatible_with
          [Layout::ExtraSpacing]
        end

        def investigate(_processed_source)
          return if processed_source.blank?

          token_aligner.offending_tokens.each do |let|
            add_offense(let, location: :end)
          end
        end

        def autocorrect(let)
          lambda do |corrector|
            corrector.insert_before(
              let.loc.end,
              token_aligner.indent_for(let)
            )
          end
        end

        private

        def token_aligner
          @token_aligner ||=
            RuboCop::RSpec::AlignLetBrace.new(processed_source.ast, :end)
        end
      end
    end
  end
end
