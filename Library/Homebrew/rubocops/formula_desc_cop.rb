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
        attr_accessor :formula_name, :description, :source_buffer, :line_number, :line_begin_pos,
                      :desc_begin_pos, :call_node

        def audit_formula(node, class_node, _parent_class_node, body)
          check(node, body, class_node.const_name)
        end

        private

        def check(node, body, formula_name)
          body.each_child_node(:send) do |call_node|
            _receiver, call_name, args = *call_node
            next if call_name != :desc || args.children[0].empty?
            @formula_name = formula_name
            @description = args.children[0]
            @source_buffer = call_node.source_range.source_buffer
            @line_number = call_node.loc.line
            @line_begin_pos = call_node.source_range.source_buffer.line_range(call_node.loc.line).begin_pos
            @desc_begin_pos = call_node.children[2].source_range.begin_pos
            @call_node = call_node

            check_for_desc_length_offense

            check_for_offense(/(command ?line)/i,
                              "Description should use \"command-line\" instead of \"%s\"")

            check_for_offense(/^(an?)\s/i,
                              "Description shouldn't start with an indefinite article (%s)")

            check_for_offense(/^#{formula_name}/i,
                              "Description shouldn't include the formula name")
            return nil
          end
          add_offense(node, node.source_range, "Formula should have a desc (Description).")
        end

        def check_for_offense(regex, offense_msg)
          # This method checks if particular regex has a match within formula's desc
          # If so, adds a violation
          match_object = @description.match(regex)
          if match_object
            column = @desc_begin_pos + match_object.begin(0) - @line_begin_pos + 1
            length = match_object.to_s.length
            offense_source_range = source_range(source_buffer, @line_number, column, length)
            offense_msg = offense_msg % [match_object]
            add_offense(@call_node, offense_source_range, offense_msg)
          end
        end

        def check_for_desc_length_offense
          # This method checks if desc length > max_desc_length
          # If so, adds a violation
          desc_length = "#{@formula_name}: #{@description}".length
          max_desc_length = 80
          if desc_length > max_desc_length
            column = @desc_begin_pos - @line_begin_pos
            length = @call_node.children[2].source_range.size
            offense_source_range = source_range(source_buffer, @line_number, column, length)
            desc_length_offense_msg = <<-EOS.undent
              Description is too long. "name: desc" should be less than #{max_desc_length} characters.
              Length is calculated as #{@formula_name} + desc. (currently #{"#{@formula_name}: #{@description}".length})
            EOS
            add_offense(@call_node, offense_source_range, desc_length_offense_msg)
          end
        end
      end
    end
  end
end
