module RuboCop
  module Cop
    module RSpec
      # Checks that chains of messages contain more than one element.
      #
      # @example
      #   # bad
      #   allow(foo).to receive_message_chain(:bar).and_return(42)
      #
      #   # good
      #   allow(foo).to receive(:bar).and_return(42)
      #
      #   # also good
      #   allow(foo).to receive(:bar, :baz)
      #   allow(foo).to receive("bar.baz")
      #
      class SingleArgumentMessageChain < Cop
        MSG = 'Use `%<recommended>s` instead of calling '\
              '`%<called>s` with a single argument.'.freeze

        def_node_matcher :message_chain, <<-PATTERN
          (send _ {:receive_message_chain :stub_chain} $_)
        PATTERN

        def_node_matcher :single_key_hash?, '(hash pair)'

        def on_send(node)
          message_chain(node) do |arg|
            return if arg.to_s.include?('.')

            return if arg.hash_type? && !single_key_hash?(arg)

            add_offense(node, location: :selector)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.selector, replacement(node.method_name))
            message_chain(node) do |arg|
              autocorrect_hash_arg(corrector, arg) if single_key_hash?(arg)
            end
          end
        end

        private

        def autocorrect_hash_arg(corrector, arg)
          key, value = *arg.children.first

          corrector.replace(arg.loc.expression, key_to_arg(key))
          corrector.insert_after(arg.parent.loc.end,
                                 ".and_return(#{value.source})")
        end

        def key_to_arg(node)
          key, = *node
          node.sym_type? ? ":#{key}" : node.source
        end

        def replacement(method)
          method.equal?(:receive_message_chain) ? 'receive' : 'stub'
        end

        def message(node)
          method = node.method_name

          format(MSG, recommended: replacement(method), called: method)
        end
      end
    end
  end
end
