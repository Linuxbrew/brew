require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for correct order of components in Formulae.
      #
      # - `component_precedence_list` has component hierarchy in a nested list
      #   where each sub array contains components' details which are at same precedence level
      class ComponentsOrder < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
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
            [{ name: :pour_bottle?, type: :block_call }],
            [{ name: :devel,    type: :block_call }],
            [{ name: :head,     type: :block_call }],
            [{ name: :bottle,   type: :method_call }],
            [{ name: :keg_only, type: :method_call }],
            [{ name: :option,   type: :method_call }],
            [{ name: :deprecated_option, type: :method_call }],
            [{ name: :depends_on, type: :method_call }],
            [{ name: :conflicts_with, type: :method_call }],
            [{ name: :skip_clean, type: :method_call }],
            [{ name: :cxxstdlib_check, type: :method_call }],
            [{ name: :link_overwrite, type: :method_call }],
            [{ name: :fails_with, type: :method_call }, { name: :fails_with, type: :block_call }],
            [{ name: :go_resource, type: :block_call }, { name: :resource, type: :block_call }],
            [{ name: :patch, type: :method_call }, { name: :patch, type: :block_call }],
            [{ name: :needs, type: :method_call }],
            [{ name: :install, type: :method_definition }],
            [{ name: :post_install, type: :method_definition }],
            [{ name: :caveats, type: :method_definition }],
            [{ name: :plist_options, type: :method_call }, { name: :plist, type: :method_definition }],
            [{ name: :test, type: :block_call }],
          ]

          @present_components = component_precedence_list.map do |components|
            relevant_components = []
            components.each do |component|
              case component[:type]
              when :method_call
                relevant_components += find_method_calls_by_name(body_node, component[:name]).to_a
              when :block_call
                relevant_components += find_blocks(body_node, component[:name]).to_a
              when :method_definition
                relevant_components << find_method_def(body_node, component[:name])
              end
            end
            relevant_components.delete_if(&:nil?)
          end

          # Check if each present_components is above rest of the present_components
          @present_components.take(@present_components.size - 1).each_with_index do |preceding_component, p_idx|
            next if preceding_component.empty?

            @present_components.drop(p_idx + 1).each do |succeeding_component|
              next if succeeding_component.empty?

              @offensive_nodes = check_precedence(preceding_component, succeeding_component)
              component_problem @offensive_nodes[0], @offensive_nodes[1] if @offensive_nodes
            end
          end
        end

        # `aspell`: options and resources should be grouped by language
        WHITELIST = %w[
          aspell
        ].freeze

        # Method to format message for reporting component precedence violations
        def component_problem(c1, c2)
          return if WHITELIST.include?(@formula_name)

          problem "`#{format_component(c1)}` (line #{line_number(c1)}) " \
                  "should be put before `#{format_component(c2)}` " \
                  "(line #{line_number(c2)})"
        end

        # autocorrect method gets called just after component_problem method call
        def autocorrect(_node)
          succeeding_node = @offensive_nodes[0]
          preceding_node = @offensive_nodes[1]
          lambda do |corrector|
            reorder_components(corrector, succeeding_node, preceding_node)
          end
        end

        # Reorder two nodes in the source, using the corrector instance in autocorrect method.
        # Components of same type are grouped together when rewriting the source.
        # Linebreaks are introduced if components are of two different methods/blocks/multilines.
        def reorder_components(corrector, node1, node2)
          # order_idx : node1's index in component_precedence_list
          # curr_p_idx: node1's index in preceding_comp_arr
          # preceding_comp_arr: array containing components of same type
          order_idx, curr_p_idx, preceding_comp_arr = get_state(node1)

          # curr_p_idx.positive? means node1 needs to be grouped with its own kind
          if curr_p_idx.positive?
            node2 = preceding_comp_arr[curr_p_idx - 1]
            indentation = " " * (start_column(node2) - line_start_column(node2))
            line_breaks = node2.multiline? ? "\n\n" : "\n"
            corrector.insert_after(node2.source_range, line_breaks + indentation + node1.source)
          else
            indentation = " " * (start_column(node2) - line_start_column(node2))
            # No line breaks upto version_scheme, order_idx == 8
            line_breaks = (order_idx > 8) ? "\n\n" : "\n"
            corrector.insert_before(node2.source_range, node1.source + line_breaks + indentation)
          end
          corrector.remove(range_with_surrounding_space(range: node1.source_range, side: :left))
        end

        # Returns precedence index and component's index to properly reorder and group during autocorrect
        def get_state(node1)
          @present_components.each_with_index do |comp, idx|
            return [idx, comp.index(node1), comp] if comp.member?(node1)
          end
        end
      end
    end
  end
end
