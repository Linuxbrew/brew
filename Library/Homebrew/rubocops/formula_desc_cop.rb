module RuboCop
  module Cop
    module Homebrew
      class FormulaDesc < Cop
        def on_class(node)
          class_node, parent_class_node, body = *node
          formula_name = class_node.const_name
          return unless parent_class_node && parent_class_node.const_name == "Formula" && body
          check(node, body, formula_name)
        end

        private

        def check(node, body, formula_name)
          body.each_child_node(:send) do |call_node|
            _receiver, call_name, args = *call_node
            next unless call_name == :desc && !args.children[0].empty?
            description = args.children[0]

            source_buffer = call_node.source_range.source_buffer
            line_number = call_node.loc.line
            line_begin_pos = call_node.source_range.source_buffer.line_range(call_node.loc.line).begin_pos
            desc_begin_pos = call_node.children[2].source_range.begin_pos

            linelength = "#{formula_name}: #{description}".length
            if linelength > 80
              column = desc_begin_pos - line_begin_pos
              length = call_node.children[2].source_range.size
              sourcerange = source_range(source_buffer, line_number, column, length)
              message = <<-EOS.strip_indent
                        Description is too long. \"name: desc\" should be less than 80 characters.
                        Length is calculated as #{formula_name} + desc. (currently #{linelength})
                        EOS
              add_offense(call_node, sourcerange, message)
            end

            match_object = description.match(/([Cc]ommand ?line)/)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              add_offense(call_node, sourcerange, "Description should use \"command-line\" instead of \"#{match_object}\"")
            end

            match_object = description.match(/^([Aa]n?)\s/)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              add_offense(call_node, sourcerange, "Description shouldn't start with an indefinite article (#{match_object})")
            end

            match_object = description.match(/^#{formula_name}/i)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              add_offense(call_node, sourcerange, "Description shouldn't include the formula name")
            end
            return
          end
          add_offense(node, node.source_range, "Formula should have a desc (Description).")
        end
      end
    end
  end
end
