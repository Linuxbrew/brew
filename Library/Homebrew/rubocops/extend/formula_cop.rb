module RuboCop
  module Cop
    class FormulaCop < Cop
      @registry = Cop.registry

      # This method is called by RuboCop and is the main entry point
      def on_class(node)
        file_path = processed_source.buffer.name
        return unless file_path_allowed?(file_path)
        class_node, parent_class_node, body = *node
        return unless formula_class?(parent_class_node)
        return unless respond_to?(:audit_formula)
        @formula_name = class_name(class_node)
        audit_formula(node, class_node, parent_class_node, body)
      end

      # Checks for regex match of pattern in the node and
      # Sets the appropriate instance variables to report the match
      def regex_match_group(node, pattern)
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

      # Returns method_node matching method_name
      def find_node_method_by_name(node, method_name)
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

      # Returns an array of method call nodes matching method_name inside node
      def find_method_calls_by_name(node, method_name)
        return if node.nil?
        node.each_child_node(:send).select { |method_node| method_name == method_node.method_name }
      end

      # Returns a block named block_name inside node
      def find_block(node, block_name)
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

      # Returns an array of block nodes named block_name inside node
      def find_blocks(node, block_name)
        return if node.nil?
        node.each_child_node(:block).select { |block_node| block_name == block_node.method_name }
      end

      # Returns a method definition node with method_name
      def find_method_def(node, method_name)
        return if node.nil?
        node.each_child_node(:def) do |def_node|
          def_method_name = method_name(def_node)
          next unless method_name == def_method_name
          @offensive_node = def_node
          @offense_source_range = def_node.source_range
          return def_node
        end
        # If not found then, parent node becomes the offensive node
        @offensive_node = node.parent
        @offense_source_range = node.parent.source_range
        nil
      end

      # Check if a method is called inside a block
      def method_called_in_block?(node, method_name)
        block_body = node.children[2]
        block_body.each_child_node(:send) do |call_node|
          next unless call_node.method_name == method_name
          @offensive_node = call_node
          @offense_source_range = call_node.source_range
          return true
        end
        false
      end

      # Check if method_name is called among the direct children nodes in the given node
      def method_called?(node, method_name)
        node.each_child_node(:send) do |call_node|
          next unless call_node.method_name == method_name
          @offensive_node = call_node
          @offense_source_range = call_node.source_range
          return true
        end
        false
      end

      # Checks for precedence, returns the first pair of precedence violating nodes
      def check_precedence(first_nodes, next_nodes)
        next_nodes.each do |each_next_node|
          first_nodes.each do |each_first_node|
            if component_precedes?(each_first_node, each_next_node)
              return [each_first_node, each_next_node]
            end
          end
        end
        nil
      end

      # If first node does not precede next_node, sets appropriate instance variables for reporting
      def component_precedes?(first_node, next_node)
        return false if line_number(first_node) < line_number(next_node)
        @offense_source_range = first_node.source_range
        @offensive_node = first_node
        true
      end

      # Returns the array of arguments of the method_node
      def parameters(method_node)
        return unless method_node.send_type?
        method_node.method_args
      end

      # Returns the begin position of the node's line in source code
      def line_start_column(node)
        node.source_range.source_buffer.line_range(node.loc.line).begin_pos
      end

      # Returns the begin position of the node in source code
      def start_column(node)
        node.source_range.begin_pos
      end

      # Returns the line number of the node
      def line_number(node)
        node.loc.line
      end

      # Returns the class node's name, nil if not a class node
      def class_name(node)
        @offensive_node = node
        @offense_source_range = node.source_range
        node.const_name
      end

      # Returns the method name for a def node
      def method_name(node)
        node.children[0] if node.def_type?
      end

      # Returns the node size in the source code
      def size(node)
        node.source_range.size
      end

      # Returns the block length of the block node
      def block_size(block)
        block_length(block)
      end

      # Source buffer is required as an argument to report style violations
      def source_buffer(node)
        node.source_range.source_buffer
      end

      # Returns the string representation if node is of type str
      def string_content(node)
        node.str_content if node.type == :str
      end

      # Returns printable component name
      def format_component(component_node)
        return component_node.method_name if component_node.send_type? || component_node.block_type?
        method_name(component_node) if component_node.def_type?
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
