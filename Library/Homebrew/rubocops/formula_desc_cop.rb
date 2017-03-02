require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module Homebrew
      # This cop audits `desc` in Formulae
      #
      # - Checks for existence of `desc`
      # - Checks if size of `desc` > 80
      # - Checks if `desc` begins with an article
      # - Checks for correct usage of `command-line` in `desc`
      # - Checks if `desc` contains the formula name

      class FormulaDesc < FormulaCop
        def audit_formula(node, class_node, _parent_class_node, body)
          check(node, body, class_node.const_name)
        end

        private

        def check(node, body, formula_name)
          body.each_child_node(:send) do |call_node|
            _receiver, call_name, args = *call_node
            next if call_name != :desc || args.children[0].empty?
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
              message = <<-EOS.undent
                Description is too long. "name: desc" should be less than 80 characters.
                Length is calculated as #{formula_name} + desc. (currently #{linelength})
              EOS
              add_offense(call_node, sourcerange, message)
            end

            match_object = description.match(/(command ?line)/i)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              message = "Description should use \"command-line\" instead of \"#{match_object}\""
              add_offense(call_node, sourcerange, message)
            end

            match_object = description.match(/^(an?)\s/i)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              message = "Description shouldn't start with an indefinite article (#{match_object})"
              add_offense(call_node, sourcerange, message)
            end

            match_object = description.match(/^#{formula_name}/i)
            if match_object
              column = desc_begin_pos+match_object.begin(0)-line_begin_pos+1
              length = match_object.to_s.length
              sourcerange = source_range(source_buffer, line_number, column, length)
              message = "Description shouldn't include the formula name"
              add_offense(call_node, sourcerange, message)
            end
            return nil
          end
          add_offense(node, node.source_range, "Formula should have a desc (Description).")
        end
      end
    end
  end
end
