require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `options` in Formulae
      class Options < FormulaCop
        DEPRECATION_MSG = "macOS has been 64-bit only since 10.6 so 32-bit options are deprecated.".freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          option_call_nodes = find_every_method_call_by_name(body_node, :option)
          option_call_nodes.each do |option_call|
            option = parameters(option_call).first
            problem DEPRECATION_MSG if regex_match_group(option, /32-bit/)
          end
        end
      end
    end
  end
end
