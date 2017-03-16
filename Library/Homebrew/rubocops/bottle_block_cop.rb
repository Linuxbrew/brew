require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module Homebrew
      # This cop audits `bottle` block in Formulae
      #
      # - `rebuild` should be used instead of `revision` in `bottle` block

      class CorrectBottleBlock < FormulaCop
        MSG = "Use rebuild instead of revision in bottle block".freeze

        def audit_formula(_node, _class_node, _parent_class_node, formula_class_body_node)
          bottle = find_block(formula_class_body_node, :bottle)
          return if bottle.nil? || block_size(bottle).zero?
          problem "Use rebuild instead of revision in bottle block" if method_called?(bottle, :revision)
        end

        private

        def autocorrect(node)
          lambda do |corrector|
            correction = node.source.sub("revision", "rebuild")
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end
      end
    end
  end
end
