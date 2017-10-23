require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      class ClassName < FormulaCop
        DEPRECATED_CLASSES = %w[
          GithubGistFormula
          ScriptFileFormula
          AmazonWebServicesFormula
        ].freeze

        def audit_formula(_node, _class_node, parent_class_node, _body_node)
          parent_class = class_name(parent_class_node)
          return unless DEPRECATED_CLASSES.include?(parent_class)
          problem "#{parent_class} is deprecated, use Formula instead"
        end

        private

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.source_range, "Formula")
          end
        end
      end
    end

    module FormulaAuditStrict
      # - `test do ..end` should be defined in the formula
      class Test < FormulaCop
        MSG = "A `test do` test block should be added".freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          return if find_block(body_node, :test)
          problem MSG
        end
      end
    end
  end
end
