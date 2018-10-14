# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # Checks for consistent method usage in feature specs.
        #
        # By default, the cop disables all Capybara-specific methods that have
        # the same native RSpec method (e.g. are just aliases). Some teams
        # however may prefer using some of the Capybara methods (like `feature`)
        # to make it obvious that the test uses Capybara, while still disable
        # the rest of the methods, like `given` (alias for `let`), `background`
        # (alias for `before`), etc. You can configure which of the methods to
        # be enabled by using the EnabledMethods configuration option.
        #
        # @example
        #   # bad
        #   feature 'User logs in' do
        #     given(:user) { User.new }
        #
        #     background do
        #       visit new_session_path
        #     end
        #
        #     scenario 'with OAuth' do
        #       # ...
        #     end
        #   end
        #
        #   # good
        #   describe 'User logs in' do
        #     let(:user) { User.new }
        #
        #     before do
        #       visit new_session_path
        #     end
        #
        #     it 'with OAuth' do
        #       # ...
        #     end
        #   end
        class FeatureMethods < Cop
          MSG = 'Use `%<replacement>s` instead of `%<method>s`.'.freeze

          # https://git.io/v7Kwr
          MAP = {
            background: :before,
            scenario:   :it,
            xscenario:  :xit,
            given:      :let,
            given!:     :let!,
            feature:    :describe
          }.freeze

          def_node_matcher :spec?, <<-PATTERN
            (block
              (send {(const nil? :RSpec) nil?} {:describe :feature} ...)
            ...)
          PATTERN

          def_node_matcher :feature_method, <<-PATTERN
            (block
              $(send {(const nil? :RSpec) nil?} ${#{MAP.keys.map(&:inspect).join(' ')}} ...)
            ...)
          PATTERN

          def on_block(node)
            return unless inside_spec?(node)

            feature_method(node) do |send_node, match|
              next if enabled?(match)

              add_offense(
                send_node,
                location: :selector,
                message: format(MSG, method: match, replacement: MAP[match])
              )
            end
          end

          def autocorrect(node)
            lambda do |corrector|
              corrector.replace(node.loc.selector, MAP[node.method_name].to_s)
            end
          end

          private

          def inside_spec?(node)
            return spec?(node) if root_node?(node)

            root = node.ancestors.find { |parent| root_node?(parent) }
            spec?(root)
          end

          def root_node?(node)
            node.parent.nil? || root_with_siblings?(node.parent)
          end

          def root_with_siblings?(node)
            node.begin_type? && node.parent.nil?
          end

          def enabled?(method_name)
            enabled_methods.include?(method_name)
          end

          def enabled_methods
            cop_config
              .fetch('EnabledMethods', [])
              .map(&:to_sym)
          end
        end
      end
    end
  end
end
