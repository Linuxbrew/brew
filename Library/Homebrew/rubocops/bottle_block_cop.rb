module RuboCop
  module Cop
   module CustomCops 
      class CorrectBottleBlock < Cop
        MSG = 'Use rebuild instead of revision in bottle block'.freeze

        def on_block(node)
          return if block_length(node).zero?
          method, _args, _body = *node

          keyword, method_name = *method

          if method_name.equal?(:bottle) and has_revision?(_body)
            add_offense(node, :expression)
          end
        end

        private

        def autocorrect(node)
          ->(corrector) do
            # Check for revision
            method, _args, _body = *node
            if has_revision?(_body)
              replace_revision(corrector, node)
            end
          end
        end

        def has_revision?(body)
          body.children.each do |method_call_node|
            _receiver, _method_name, *args = *method_call_node
            if _method_name == :revision
              return true
            end
          end
          false
        end

        def replace_revision(corrector, node)
          new_source = String.new
          node.source.each_line do |line|
            if line =~ /\A\s*revision/
              line = line.sub('revision','rebuild')
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
