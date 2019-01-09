module RuboCop
  module Cop
    module RSpec
      module Capybara
        # Checks that no expectations are set on Capybara's `current_path`.
        #
        # The `have_current_path` matcher (http://www.rubydoc.info/github/
        # teamcapybara/capybara/master/Capybara/RSpecMatchers#have_current_path-
        # instance_method) should be used on `page` to set expectations on
        # Capybara's current path, since it uses Capybara's waiting
        # functionality (https://github.com/teamcapybara/capybara/blob/master/
        # README.md#asynchronous-javascript-ajax-and-friends) which ensures that
        # preceding actions (like `click_link`) have completed.
        #
        # @example
        #   # bad
        #   expect(current_path).to eq('/callback')
        #   expect(page.current_path).to match(/widgets/)
        #
        #   # good
        #   expect(page).to have_current_path("/callback")
        #   expect(page).to have_current_path(/widgets/)
        #
        class CurrentPathExpectation < Cop
          MSG = 'Do not set an RSpec expectation on `current_path` in ' \
                'Capybara feature specs - instead, use the ' \
                '`have_current_path` matcher on `page`'.freeze

          def_node_matcher :expectation_set_on_current_path, <<-PATTERN
            (send nil? :expect (send {(send nil? :page) nil?} :current_path))
          PATTERN

          # Supported matchers: eq(...) / match(/regexp/) / match('regexp')
          def_node_matcher :as_is_matcher, <<-PATTERN
            (send
              #expectation_set_on_current_path ${:to :not_to :to_not}
              ${(send nil? :eq ...) (send nil? :match (regexp ...))})
          PATTERN

          def_node_matcher :regexp_str_matcher, <<-PATTERN
            (send
              #expectation_set_on_current_path ${:to :not_to :to_not}
              $(send nil? :match (str $_)))
          PATTERN

          def on_send(node)
            expectation_set_on_current_path(node) do
              add_offense(node, location: :selector)
            end
          end

          def autocorrect(node)
            lambda do |corrector|
              return unless node.chained?

              as_is_matcher(node.parent) do |to_sym, matcher_node|
                rewrite_expectation(corrector, node, to_sym, matcher_node)
              end

              regexp_str_matcher(node.parent) do |to_sym, matcher_node, regexp|
                rewrite_expectation(corrector, node, to_sym, matcher_node)
                convert_regexp_str_to_literal(corrector, matcher_node, regexp)
              end
            end
          end

          private

          def rewrite_expectation(corrector, node, to_symbol, matcher_node)
            current_path_node = node.first_argument
            corrector.replace(current_path_node.loc.expression, 'page')
            corrector.replace(node.parent.loc.selector, 'to')
            matcher_method = if to_symbol == :to
                               'have_current_path'
                             else
                               'have_no_current_path'
                             end
            corrector.replace(matcher_node.loc.selector, matcher_method)
          end

          def convert_regexp_str_to_literal(corrector, matcher_node, regexp_str)
            str_node = matcher_node.first_argument
            regexp_expr = Regexp.new(regexp_str).inspect
            corrector.replace(str_node.loc.expression, regexp_expr)
          end
        end
      end
    end
  end
end
