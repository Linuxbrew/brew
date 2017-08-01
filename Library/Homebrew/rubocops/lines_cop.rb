require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for various miscellaneous Homebrew coding styles
      class Lines < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          [:automake, :autoconf, :libtool].each do |dependency|
            next unless depends_on?(dependency)
            problem ":#{dependency} is deprecated. Usage should be \"#{dependency}\""
          end

          problem ':apr is deprecated. Usage should be "apr-util"' if depends_on?(:apr)
          problem ":tex is deprecated" if depends_on?(:tex)
        end
      end
    end
  end
end
