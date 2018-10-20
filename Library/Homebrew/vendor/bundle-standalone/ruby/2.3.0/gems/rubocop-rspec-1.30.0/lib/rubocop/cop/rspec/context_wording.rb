# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # `context` block descriptions should start with 'when', or 'with'.
      #
      # @see https://github.com/reachlocal/rspec-style-guide#context-descriptions
      # @see http://www.betterspecs.org/#contexts
      #
      # @example `Prefixes` configuration option, defaults: 'when', 'with', and
      # 'without'
      #   Prefixes:
      #     - when
      #     - with
      #     - without
      #     - if
      #
      # @example
      #   # bad
      #   context 'the display name not present' do
      #     # ...
      #   end
      #
      #   # good
      #   context 'when the display name is not present' do
      #     # ...
      #   end
      class ContextWording < Cop
        MSG = 'Start context description with %<prefixes>s.'.freeze

        def_node_matcher :context_wording, <<-PATTERN
          (block (send _ { :context :shared_context } $(str #bad_prefix?)) ...)
        PATTERN

        def on_block(node)
          context_wording(node) do |context|
            add_offense(context, message: message)
          end
        end

        private

        def bad_prefix?(description)
          !prefixes.include?(description.split.first)
        end

        def prefixes
          cop_config['Prefixes'] || []
        end

        def message
          format(MSG, prefixes: joined_prefixes)
        end

        def joined_prefixes
          quoted = prefixes.map { |prefix| "'#{prefix}'" }
          return quoted.first if quoted.size == 1

          quoted << "or #{quoted.pop}"
          quoted.join(', ')
        end
      end
    end
  end
end
