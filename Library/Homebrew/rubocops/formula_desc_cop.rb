require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module FormulaAuditStrict
      # This cop audits `desc` in Formulae
      #
      # - Checks for existence of `desc`
      # - Checks if size of `desc` > 80
      # - Checks if `desc` begins with an article
      # - Checks for correct usage of `command-line` in `desc`
      # - Checks if `desc` contains the formula name
      class Desc < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body)
          desc_call = find_node_method_by_name(body, :desc)

          if desc_call.nil?
            problem "Formula should have a desc (Description)."
            return
          end

          desc = parameters(desc_call).first
          desc_length = "#{@formula_name}: #{string_content(desc)}".length
          max_desc_length = 80
          if desc_length > max_desc_length
            problem <<-EOS.undent
              Description is too long. "name: desc" should be less than #{max_desc_length} characters.
              Length is calculated as #{@formula_name} + desc. (currently #{desc_length})
            EOS
          end

          # Check if command-line is wrongly used in formula's desc
          if match = regex_match_group(desc, /(command ?line)/i)
            problem "Description should use \"command-line\" instead of \"#{match}\""
          end

          if match = regex_match_group(desc, /^(an?)\s/i)
            problem "Description shouldn't start with an indefinite article (#{match})"
          end

          # Check if formula's name is used in formula's desc
          problem "Description shouldn't include the formula name" if regex_match_group(desc, /^#{@formula_name}/i)
        end
      end
    end
  end
end
