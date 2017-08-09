require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      class Caveats < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          caveats_strings.each do |n|
            next unless regex_match_group(n, /\bsetuid\b/i)
            problem "Don't recommend setuid in the caveats, suggest sudo instead."
          end
        end
      end
    end
  end
end
