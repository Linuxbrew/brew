# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for explicitly referenced test subjects.
      #
      # RSpec lets you declare an "implicit subject" using `subject { ... }`
      # which allows for tests like `it { should be_valid }`. If you need to
      # reference your test subject you should explicitly name it using
      # `subject(:your_subject_name) { ... }`. Your test subjects should be
      # the most important object in your tests so they deserve a descriptive
      # name.
      #
      # @example
      #   # bad
      #   RSpec.describe User do
      #     subject { described_class.new }
      #
      #     it 'is valid' do
      #       expect(subject.valid?).to be(true)
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     subject(:user) { described_class.new }
      #
      #     it 'is valid' do
      #       expect(user.valid?).to be(true)
      #     end
      #   end
      #
      #   # also good
      #   RSpec.describe Foo do
      #     subject(:user) { described_class.new }
      #
      #     it { should be_valid }
      #   end
      class NamedSubject < Cop
        MSG = 'Name your test subject if you need '\
              'to reference it explicitly.'.freeze

        def_node_matcher :rspec_block?, <<-PATTERN
          {
            #{Examples::ALL.block_pattern}
            #{Hooks::ALL.block_pattern}
          }
        PATTERN

        def_node_search :subject_usage, '$(send nil? :subject)'

        def on_block(node)
          return unless rspec_block?(node)

          subject_usage(node) do |subject_node|
            add_offense(subject_node, location: :selector)
          end
        end
      end
    end
  end
end
