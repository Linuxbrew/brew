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
          check(formula_class_body_node)
        end

        private

        def check(formula_class_body_node)
          formula_class_body_node.each_child_node(:block) do |block_node|
            next if block_length(block_node).zero?
            method, _args, block_body = *block_node
            _keyword, method_name = *method
            next unless method_name == :bottle
            check_revision?(block_body)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            correction = node.source.sub("revision", "rebuild")
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end

        def check_revision?(body)
          body.children.each do |method_call_node|
            _receiver, method_name, _args = *method_call_node
            next unless method_name == :revision
            add_offense(method_call_node, :expression)
          end
        end
      end
    end
  end
end
