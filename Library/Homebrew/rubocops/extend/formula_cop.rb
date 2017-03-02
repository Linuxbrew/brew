module RuboCop
  module Cop
    module Homebrew
      class FormulaCop < Cop
        @registry = Cop.registry

        def on_class(node)
          # This method is called by RuboCop and is the main entry point
          class_node, parent_class_node, body = *node
          return unless a_formula_class?(parent_class_node)
          audit_formula(node, class_node, parent_class_node, body)
        end

        private

        def a_formula_class?(parent_class_node)
          parent_class_node && parent_class_node.const_name == "Formula"
        end
      end
    end
  end
end
