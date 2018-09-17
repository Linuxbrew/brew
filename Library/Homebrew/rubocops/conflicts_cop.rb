require "rubocops/extend/formula_cop"
require "extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits versioned Formulae for `conflicts_with`
      class Conflicts < FormulaCop
        MSG = "Versioned formulae should not use `conflicts_with`. " \
              "Use `keg_only :versioned_formula` instead.".freeze

        WHITELIST = %w[
          bash-completion@
        ].freeze

        def audit_formula(_node, _class_node, _parent_class_node, body)
          return unless versioned_formula?

          problem MSG if !@formula_name.start_with?(*WHITELIST) &&
                         method_called_ever?(body, :conflicts_with)
        end
      end
    end
  end
end
