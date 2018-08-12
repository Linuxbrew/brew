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

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.source_range, "Formula")
          end
        end
      end
    end

    module FormulaAuditStrict
      # - `test do ..end` should be meaningfully defined in the formula
      class Test < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          test = find_block(body_node, :test)

          unless test
            problem "A `test do` test block should be added"
            return
          end

          if test.body.nil?
            problem "`test do` should not be empty"
            return
          end

          return unless test.body.single_line? &&
                        test.body.source.to_s == "true"
          problem "`test do` should contain a real test"
        end
      end
    end
  end
end
