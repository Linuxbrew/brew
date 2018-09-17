require "rubocops/extend/formula_cop"
require "extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `desc` in Formulae
      #
      # - Checks for existence of `desc`
      # - Checks if size of `desc` > 80
      class DescLength < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          desc_call = find_node_method_by_name(body_node, :desc)

          # Check if a formula's desc is present
          if desc_call.nil?
            problem "Formula should have a desc (Description)."
            return
          end

          # Check the formula's desc length. Should be >0 and <80 characters.
          desc = parameters(desc_call).first
          pure_desc_length = string_content(desc).length
          if pure_desc_length.zero?
            problem "The desc (description) should not be an empty string."
            return
          end

          desc_length = "#{@formula_name}: #{string_content(desc)}".length
          max_desc_length = 80
          return if desc_length <= max_desc_length

          problem "Description is too long. \"name: desc\" should be less than #{max_desc_length} characters. " \
                  "Length is calculated as #{@formula_name} + desc. (currently #{desc_length})"
        end
      end
    end

    module FormulaAuditStrict
      # This cop audits `desc` in Formulae
      #
      # - Checks for leading/trailing whitespace in `desc`
      # - Checks if `desc` begins with an article
      # - Checks for correct usage of `command-line` in `desc`
      # - Checks description starts with a capital letter
      # - Checks if `desc` contains the formula name
      # - Checks if `desc` ends with a full stop (apart from in the case of "etc.")
      class Desc < FormulaCop
        VALID_LOWERCASE_WORDS = %w[
          ex
          eXtensible
          iOS
          macOS
          malloc
          ooc
          preexec
          x86
          xUnit
        ].freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          desc_call = find_node_method_by_name(body_node, :desc)
          return if desc_call.nil?

          desc = parameters(desc_call).first

          # Check for leading whitespace.
          if regex_match_group(desc, /^\s+/)
            problem "Description shouldn't have a leading space"
          end

          # Check for trailing whitespace.
          if regex_match_group(desc, /\s+$/)
            problem "Description shouldn't have a trailing space"
          end

          # Check if command-line is wrongly used in formula's desc
          if match = regex_match_group(desc, /(command ?line)/i)
            c = match.to_s.chars.first
            problem "Description should use \"#{c}ommand-line\" instead of \"#{match}\""
          end

          # Check if a/an are used in a formula's desc
          if match = regex_match_group(desc, /^(an?)\s/i)
            problem "Description shouldn't start with an indefinite article i.e. \"#{match.to_s.strip}\""
          end

          # Check if invalid uppercase words are at the start of a
          # formula's desc
          if !VALID_LOWERCASE_WORDS.include?(string_content(desc).split.first) &&
             regex_match_group(desc, /^[a-z]/)
            problem "Description should start with a capital letter"
          end

          # Check if formula's desc starts with formula's name
          if regex_match_group(desc, /^#{@formula_name} /i)
            problem "Description shouldn't start with the formula name"
          end

          # Check if a full stop is used at the end of a formula's desc (apart from in the case of "etc.")
          return unless regex_match_group(desc, /\.$/) && !string_content(desc).end_with?("etc.")

          problem "Description shouldn't end with a full stop"
        end

        def autocorrect(node)
          lambda do |corrector|
            correction = node.source
            first_word = string_content(node).split.first
            unless VALID_LOWERCASE_WORDS.include?(first_word)
              first_char = first_word.to_s.chars.first
              correction.sub!(/^(['"]?)([a-z])/, "\\1#{first_char.upcase}")
            end
            correction.sub!(/^(['"]?)an?\s/i, "\\1")
            correction.gsub!(/(ommand ?line)/i, "ommand-line")
            correction.gsub!(/(^|[^a-z])#{@formula_name}([^a-z]|$)/i, "\\1\\2")
            correction.gsub!(/^(['"]?)\s+/, "\\1")
            correction.gsub!(/\s+(['"]?)$/, "\\1")
            correction.gsub!(/\.(['"]?)$/, "\\1")
            correction.gsub!(/^\s+/, "")
            correction.gsub!(/\s+$/, "")
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end
      end
    end
  end
end
