module RuboCop
  module Cop
    module RSpec
      # Checks that around blocks actually run the test.
      #
      # @example
      #   # bad
      #   around do
      #     some_method
      #   end
      #
      #   around do |test|
      #     some_method
      #   end
      #
      #   # good
      #   around do |test|
      #     some_method
      #     test.call
      #   end
      #
      #   around do |test|
      #     some_method
      #     test.run
      #   end
      class AroundBlock < Cop
        MSG_NO_ARG     = 'Test object should be passed to around block.'.freeze
        MSG_UNUSED_ARG = 'You should call `%<arg>s.call` '\
                         'or `%<arg>s.run`.'.freeze

        def_node_matcher :hook, <<-PATTERN
          (block {(send nil? :around) (send nil? :around sym)} (args $...) ...)
        PATTERN

        def_node_search :find_arg_usage, <<-PATTERN
          {(send $... {:call :run}) (send _ _ $...) (yield $...) (block-pass $...)}
        PATTERN

        def on_block(node)
          hook(node) do |(example_proxy)|
            if example_proxy.nil?
              add_no_arg_offense(node)
            else
              check_for_unused_proxy(node, example_proxy)
            end
          end
        end

        private

        def add_no_arg_offense(node)
          add_offense(node, location: :expression, message: MSG_NO_ARG)
        end

        def check_for_unused_proxy(block, proxy)
          name, = *proxy

          find_arg_usage(block) do |usage|
            return if usage.include?(s(:lvar, name))
          end

          add_offense(
            proxy,
            location: :expression,
            message: format(MSG_UNUSED_ARG, arg: name)
          )
        end
      end
    end
  end
end
