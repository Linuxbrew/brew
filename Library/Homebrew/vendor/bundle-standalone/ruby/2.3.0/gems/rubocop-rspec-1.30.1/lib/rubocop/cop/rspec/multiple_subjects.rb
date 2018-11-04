# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if an example group defines `subject` multiple times.
      #
      # @example
      #
      #   # bad
      #   describe Foo do
      #     subject(:user) { User.new }
      #     subject(:post) { Post.new }
      #   end
      #
      #   # good
      #   describe Foo do
      #     let(:user) { User.new }
      #     subject(:post) { Post.new }
      #   end
      #
      # The autocorrect behavior for this cop depends on the type of
      # duplication:
      #
      #   - If multiple named subjects are defined then this probably indicates
      #     that the overwritten subjects (all subjects except the last
      #     definition) are effectively being used to define helpers. In this
      #     case they are replaced with `let`.
      #
      #   - If multiple unnamed subjects are defined though then this can *only*
      #     be dead code and we remove the overwritten subject definitions.
      #
      #   - If subjects are defined with `subject!` then we don't autocorrect.
      #     This is enough of an edge case that people can just move this to
      #     a `before` hook on their own
      class MultipleSubjects < Cop
        MSG = 'Do not set more than one subject per example group'.freeze

        def on_block(node)
          return unless example_group?(node)

          subjects = RuboCop::RSpec::ExampleGroup.new(node).subjects

          subjects[0...-1].each do |subject|
            add_offense(subject, location: :expression)
          end
        end

        def autocorrect(node)
          return unless node.method_name.equal?(:subject) # Ignore `subject!`

          if named_subject?(node)
            rename_autocorrect(node)
          else
            remove_autocorrect(node)
          end
        end

        private

        def named_subject?(node)
          node.send_node.arguments?
        end

        def rename_autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.send_node.loc.selector, 'let')
          end
        end

        def remove_autocorrect(node)
          lambda do |corrector|
            corrector.remove(node.loc.expression)
          end
        end
      end
    end
  end
end
