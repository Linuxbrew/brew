require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAuditStrict
      # This cop checks if redundant components are present and other component errors
      #
      # - `url|checksum|mirror` should be inside `stable` block
      # - `head` and `head do` should not be simultaneously present
      # - `bottle :unneeded/:disable` and `bottle do` should not be simultaneously present

      class ComponentsRedundancy < FormulaCop
        HEAD_MSG = "`head` and `head do` should not be simultaneously present".freeze
        BOTTLE_MSG = "`bottle :modifier` and `bottle do` should not be simultaneously present".freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          stable_block = find_block(body_node, :stable)
          if stable_block
            [:url, :sha256, :mirror].each do |method_name|
              problem "`#{method_name}` should be put inside `stable` block" if method_called?(body_node, method_name)
            end
          end

          problem HEAD_MSG if method_called?(body_node, :head) &&
                              find_block(body_node, :head)

          problem BOTTLE_MSG if method_called?(body_node, :bottle) &&
                                find_block(body_node, :bottle)
        end
      end
    end
  end
end
