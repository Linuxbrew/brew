module RuboCop
  module Cop
    module CustomCops
      class CorrectBottleBlock < Cop
        MSG = "Use rebuild instead of revision in bottle block".freeze

        def on_block(node)
          return if block_length(node).zero?
          method, _args, body = *node
          _keyword, method_name = *method

          return unless method_name.equal?(:bottle) && revision?(body)
          add_offense(node, :expression)
        end

        private

        def autocorrect(node)
          lambda do |corrector|
            # Check for revision
            _method, _args, body = *node
            if revision?(body)
              replace_revision(corrector, node)
            end
          end
        end

        def revision?(body)
          body.children.each do |method_call_node|
            _receiver, method_name, _args = *method_call_node
            if method_name == :revision
              return true
            end
          end
          false
        end

        def replace_revision(corrector, node)
          new_source = ""
          node.source.each_line do |line|
            if line =~ /\A\s*revision/
              line = line.sub("revision", "rebuild")
            end
            new_source << line
          end
          corrector.insert_before(node.source_range, new_source)
          corrector.remove(node.source_range)
        end
      end
    end
  end
end
