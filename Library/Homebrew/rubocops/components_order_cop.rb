require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module Homebrew
      # This cop checks for correct order of components in a Formula
      #
      # - component_precedence_list has component hierarchy in a nested list
      #   where each sub array contains components' details which are at same precedence level
      class FormulaComponentsOrder < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, formula_class_body_node)
          component_precedence_list = [
            [{ name: :include,  type: :method_call }],
            [{ name: :desc,     type: :method_call }],
            [{ name: :homepage, type: :method_call }],
            [{ name: :url,      type: :method_call }],
            [{ name: :mirror,   type: :method_call }],
            [{ name: :version,  type: :method_call }],
            [{ name: :sha256,   type: :method_call }],
            [{ name: :revision, type: :method_call }],
            [{ name: :version_scheme, type: :method_call }],
            [{ name: :head,     type: :method_call }],
            [{ name: :stable,   type: :block_call }],
            [{ name: :bottle,   type: :block_call }],
            [{ name: :devel,    type: :block_call }],
            [{ name: :head,     type: :block_call }],
            [{ name: :bottle,   type: :method_call }],
            [{ name: :keg_only, type: :method_call }],
            [{ name: :option,   type: :method_call }],
            [{ name: :depends_on, type: :method_call }],
            [{ name: :conflicts_with, type: :method_call }],
            [{ name: :go_resource, type: :block_call }, { name: :resource, type: :block_call }],
            [{ name: :install, type: :method_definition }],
            [{ name: :caveats, type: :method_definition }],
            [{ name: :plist_options, type: :method_call }, { name: :plist, type: :method_definition }],
            [{ name: :test, type: :block_call }],
          ]

          present_components = component_precedence_list.map do |components|
            relevant_components = []
            components.each do |component|
              case component[:type]
              when :method_call
                relevant_components += find_method_calls_by_name(formula_class_body_node, component[:name]).to_a
              when :block_call
                relevant_components += find_blocks(formula_class_body_node, component[:name]).to_a
              when :method_definition
                relevant_components << find_method_def(formula_class_body_node, component[:name])
              end
            end
            relevant_components.delete_if(&:nil?)
          end

          present_components = present_components.delete_if(&:empty?)

          present_components.each_cons(2) do |preceding_component, succeeding_component|
            offensive_nodes = check_precedence(preceding_component, succeeding_component)
            component_problem offensive_nodes[0], offensive_nodes[1] if offensive_nodes
          end
        end

        private

        def component_problem(c1, c2)
          # Method to format message for reporting component precedence violations
          problem "`#{format_component(c1)}` (line #{line_number(c1)}) should be put before `#{format_component(c2)}` (line #{line_number(c2)})"
        end
      end
    end
  end
end
