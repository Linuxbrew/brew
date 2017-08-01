require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module FormulaAuditStrict
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

          # Check if a formula's desc is too long
          desc = parameters(desc_call).first
          desc_length = "#{@formula_name}: #{string_content(desc)}".length
          max_desc_length = 80
          return if desc_length <= max_desc_length
          problem <<-EOS.undent
            Description is too long. "name: desc" should be less than #{max_desc_length} characters.
            Length is calculated as #{@formula_name} + desc. (currently #{desc_length})
          EOS
        end
      end

      # This cop audits `desc` in Formulae
      #
      # - Checks if `desc` begins with an article
      # - Checks for correct usage of `command-line` in `desc`
      # - Checks description starts with a capital letter
      # - Checks if `desc` contains the formula name
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
          return unless regex_match_group(desc, /^#{@formula_name} /i)
          problem "Description shouldn't start with the formula name"
        end

        private

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
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end
      end
    end
  end
end
