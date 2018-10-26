require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for correct order of `depends_on` in Formulae.
      #
      # precedence order:
      # build-time > run-time > normal > recommended > optional
      class DependencyOrder < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          check_dependency_nodes_order(body_node)
          [:devel, :head, :stable].each do |block_name|
            block = find_block(body_node, block_name)
            next unless block

            check_dependency_nodes_order(block.body)
          end
        end

        def check_dependency_nodes_order(parent_node)
          return if parent_node.nil?

          dependency_nodes = fetch_depends_on_nodes(parent_node)
          ordered = dependency_nodes.sort_by { |node| dependency_name(node).downcase }
          ordered = sort_dependencies_by_type(ordered)
          sort_conditional_dependencies!(ordered)
          verify_order_in_source(ordered)
        end

        # Match all `depends_on` nodes among childnodes of given parent node
        def fetch_depends_on_nodes(parent_node)
          parent_node.each_child_node.select { |x| depends_on_node?(x) }
        end

        # Separate dependencies according to precedence order:
        # build-time > test > normal > recommended > optional
        def sort_dependencies_by_type(dependency_nodes)
          unsorted_deps = dependency_nodes.to_a
          ordered = []
          ordered.concat(unsorted_deps.select { |dep| buildtime_dependency? dep })
          unsorted_deps -= ordered
          ordered.concat(unsorted_deps.select { |dep| test_dependency? dep })
          unsorted_deps -= ordered
          ordered.concat(unsorted_deps.reject { |dep| negate_normal_dependency? dep })
          unsorted_deps -= ordered
          ordered.concat(unsorted_deps.select { |dep| recommended_dependency? dep })
          unsorted_deps -= ordered
          ordered.concat(unsorted_deps.select { |dep| optional_dependency? dep })
        end

        # `depends_on :apple if build.with? "foo"` should always be defined
        #  after `depends_on :foo`
        # This method reorders dependencies array according to above rule
        def sort_conditional_dependencies!(ordered)
          length = ordered.size
          idx = 0
          while idx < length
            idx1, idx2 = nil
            ordered.each_with_index do |dep, pos|
              idx = pos+1
              match_nodes = build_with_dependency_name(dep)
              next if !match_nodes || match_nodes.empty?

              idx1 = pos
              ordered.drop(idx1+1).each_with_index do |dep2, pos2|
                next unless match_nodes.index(dependency_name(dep2))

                idx2 = pos2 if idx2.nil? || pos2 > idx2
              end
              break if idx2
            end
            insert_after!(ordered, idx1, idx2+idx1) if idx2
          end
          ordered
        end

        # Verify actual order of sorted `depends_on` nodes in source code
        # Else raise RuboCop problem
        def verify_order_in_source(ordered)
          ordered.each_with_index do |dependency_node_1, idx|
            l1 = line_number(dependency_node_1)
            dependency_node_2 = nil
            ordered.drop(idx+1).each do |node2|
              l2 = line_number(node2)
              dependency_node_2 = node2 if l2 < l1
            end
            next unless dependency_node_2

            @offensive_nodes = [dependency_node_1, dependency_node_2]
            component_problem dependency_node_1, dependency_node_2
          end
        end

        # Node pattern method to match
        # `depends_on` variants
        def_node_matcher :depends_on_node?, <<~EOS
          {(if _ (send nil? :depends_on ...) nil?)
           (send nil? :depends_on ...)}
        EOS

        def_node_search :buildtime_dependency?, "(sym :build)"

        def_node_search :recommended_dependency?, "(sym :recommended)"

        def_node_search :test_dependency?, "(sym :test)"

        def_node_search :optional_dependency?, "(sym :optional)"

        def_node_search :negate_normal_dependency?, "(sym {:build :recommended :test :optional})"

        # Node pattern method to extract `name` in `depends_on :name`
        def_node_search :dependency_name_node, <<~EOS
          {(send nil? :depends_on {(hash (pair $_ _)) $({str sym} _) $(const nil? _)})
           (if _ (send nil? :depends_on {(hash (pair $_ _)) $({str sym} _) $(const nil? _)}) nil?)}
        EOS

        # Node pattern method to extract `name` in `build.with? :name`
        def_node_search :build_with_dependency_node, <<~EOS
          (send (send nil? :build) :with? $({str sym} _))
        EOS

        def insert_after!(arr, idx1, idx2)
          arr.insert(idx2+1, arr.delete_at(idx1))
        end

        def build_with_dependency_name(node)
          match_nodes = build_with_dependency_node(node)
          match_nodes = match_nodes.to_a.delete_if(&:nil?)
          match_nodes.map { |n| string_content(n) } unless match_nodes.empty?
        end

        def dependency_name(dependency_node)
          match_node = dependency_name_node(dependency_node).to_a.first
          string_content(match_node) if match_node
        end

        def autocorrect(_node)
          succeeding_node = @offensive_nodes[0]
          preceding_node = @offensive_nodes[1]
          lambda do |corrector|
            reorder_components(corrector, succeeding_node, preceding_node)
          end
        end

        private

        def component_problem(c1, c2)
          offending_node(c1)
          problem "dependency \"#{dependency_name(c1)}\" " \
                  "(line #{line_number(c1)}) should be put before dependency "\
                  "\"#{dependency_name(c2)}\" (line #{line_number(c2)})"
        end

        # Reorder two nodes in the source, using the corrector instance in autocorrect method
        def reorder_components(corrector, node1, node2)
          indentation = " " * (start_column(node2) - line_start_column(node2))
          line_breaks = "\n"
          corrector.insert_before(node2.source_range, node1.source + line_breaks + indentation)
          corrector.remove(range_with_surrounding_space(range: node1.source_range, side: :left))
        end
      end
    end
  end
end
