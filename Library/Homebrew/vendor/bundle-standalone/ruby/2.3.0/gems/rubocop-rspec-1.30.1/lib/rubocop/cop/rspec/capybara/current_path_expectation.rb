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

          def on_send(node)
            expectation_set_on_current_path(node) do
              add_offense(node, location: :selector)
            end
          end
        end
      end
    end
  end
end
