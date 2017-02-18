module RuboCop
  module Cop
    module Homebrew
      class CorrectBottleBlock < Cop
        MSG = "Use rebuild instead of revision in bottle block".freeze

        def on_block(node)
          return if block_length(node).zero?
          method, _args, body = *node
          _keyword, method_name = *method

          return unless method_name == :bottle
          check_revision?(body)
        end

        private

        def autocorrect(node)
          lambda do |corrector|
            correction = node.source.sub("revision", "rebuild")
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end

        def check_revision?(body)
          body.children.each do |method_call_node|
            _receiver, method_name, _args = *method_call_node
            next unless method_name == :revision
            add_offense(method_call_node, :expression)
          end
        end
      end
    end
  end
end
