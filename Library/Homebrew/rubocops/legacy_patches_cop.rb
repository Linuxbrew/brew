require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for and audits legacy patches in Formulae
      class LegacyPatches < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body)
          patches_node = find_method_def(body, :patches)
          return if patches_node.nil?
          legacy_patches = find_strings(patches_node)
          problem "Use the patch DSL instead of defining a 'patches' method"
          legacy_patches.each { |p| patch_problems(p) }
        end
      end

      class ExternalPatches < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body)
          patches = find_all_blocks(body, :patch)
          patches.each do |patch_block|
            url_node = find_node_method_by_name(patch_block, :url)
            url_string = parameters(url_node).first
            patch_problems(url_string)
          end
        end
      end
    end
  end
end
