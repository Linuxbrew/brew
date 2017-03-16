module RuboCop
  module Cop
    module Homebrew
      class FormulaCop < Cop
        @registry = Cop.registry

        def on_class(node)
          # This method is called by RuboCop and is the main entry point
          file_path = processed_source.buffer.name
          return unless file_path_allowed?(file_path)
          class_node, parent_class_node, body = *node
          return unless formula_class?(parent_class_node)
          return unless respond_to?(:audit_formula)
          @formula_name = class_name(class_node)
          audit_formula(node, class_node, parent_class_node, body)
        end

        def regex_match_group(node, pattern)
          # Checks for regex match of pattern in the node and
          # Sets the appropriate instance variables to report the match
          string_repr = string_content(node)
          match_object = string_repr.match(pattern)
          return unless match_object
          node_begin_pos = start_column(node)
          line_begin_pos = line_start_column(node)
          @column = node_begin_pos + match_object.begin(0) - line_begin_pos + 1
          @length = match_object.to_s.length
          @line_no = line_number(node)
          @source_buf = source_buffer(node)
          @offense_source_range = source_range(@source_buf, @line_no, @column, @length)
          @offensive_node = node
          match_object
        end

        def find_node_method_by_name(node, method_name)
          # Returns method_node matching method_name
          return if node.nil?
          node.each_child_node(:send) do |method_node|
            next unless method_node.method_name == method_name
            @offensive_node = method_node
            @offense_source_range = method_node.source_range
            return method_node
          end
          # If not found then, parent node becomes the offensive node
          @offensive_node = node.parent
          @offense_source_range = node.parent.source_range
          nil
        end

        def find_block(node, block_name)
          # Returns a block named block_name inside node
          return if node.nil?
          node.each_child_node(:block) do |block_node|
            next if block_node.method_name != block_name
            @offensive_node = block_node
            @offense_source_range = block_node.source_range
            return block_node
          end
          # If not found then, parent node becomes the offensive node
          @offensive_node = node.parent
          @offense_source_range = node.parent.source_range
          nil
        end

        def method_called?(node, method_name)
          # Check if a method is called inside a block
          block_body = node.children[2]
          block_body.each_child_node(:send) do |call_node|
            next unless call_node.method_name == method_name
            @offensive_node = call_node
            @offense_source_range = call_node.source_range
            return true
          end
          false
        end

        def parameters(method_node)
          # Returns the array of arguments of the method_node
          return unless method_node.send_type?
          method_node.method_args
        end

        def line_start_column(node)
          # Returns the begin position of the node's line in source code
          node.source_range.source_buffer.line_range(node.loc.line).begin_pos
        end

        def start_column(node)
          # Returns the begin position of the node in source code
          node.source_range.begin_pos
        end

        def line_number(node)
          # Returns the line number of the node
          node.loc.line
        end

        def class_name(node)
          # Returns the class node's name, nil if not a class node
          @offensive_node = node
          @offense_source_range = node.source_range
          node.const_name
        end

        def size(node)
          # Returns the node size in the source code
          node.source_range.size
        end

        def block_size(block)
          # Returns the block length of the block node
          block_length(block)
        end

        def source_buffer(node)
          # Source buffer is required as an argument to report style violations
          node.source_range.source_buffer
        end

        def string_content(node)
          # Returns the string representation if node is of type str
          node.str_content if node.type == :str
        end

        def problem(msg)
          add_offense(@offensive_node, @offense_source_range, msg)
        end

        private

        def formula_class?(parent_class_node)
          parent_class_node && parent_class_node.const_name == "Formula"
        end

        def file_path_allowed?(file_path)
          paths_to_exclude = [%r{/Library/Homebrew/compat/},
                              %r{/Library/Homebrew/test/}]
          return true if file_path.nil? # file_path is nil when source is directly passed to the cop eg., in specs
          file_path !~ Regexp.union(paths_to_exclude)
        end
      end
    end
  end
end
