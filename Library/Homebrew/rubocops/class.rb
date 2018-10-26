require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      class ClassName < FormulaCop
        DEPRECATED_CLASSES = %w[
          GithubGistFormula
          ScriptFileFormula
          AmazonWebServicesFormula
        ].freeze

        def audit_formula(_node, _class_node, parent_class_node, _body_node)
          parent_class = class_name(parent_class_node)
          return unless DEPRECATED_CLASSES.include?(parent_class)

          problem "#{parent_class} is deprecated, use Formula instead"
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.source_range, "Formula")
          end
        end
      end

      class TestCalls < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          test = find_block(body_node, :test)
          return unless test

          test_calls(test) do |node, params|
            p1, p2 = params
            if match = string_content(p1).match(%r{(/usr/local/(s?bin))})
              offending_node(p1)
              problem "use \#{#{match[2]}} instead of #{match[1]} in #{node}"
            end

            if node == :shell_output && node_equals?(p2, 0)
              offending_node(p2)
              problem "Passing 0 to shell_output() is redundant"
            end
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            case node.type
            when :str, :dstr
              corrector.replace(node.source_range,
                                node.source.to_s.sub(%r{(/usr/local/(s?bin))},
                                                     '#{\2}'))
            when :int
              corrector.remove(
                range_with_surrounding_comma(
                  range_with_surrounding_space(range: node.source_range,
                                               side:  :left),
                ),
              )
            end
          end
        end

        def_node_search :test_calls, <<~EOS
          (send nil? ${:system :shell_output :pipe_output} $...)
        EOS
      end
    end

    module FormulaAuditStrict
      # - `test do ..end` should be meaningfully defined in the formula.
      class Test < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          test = find_block(body_node, :test)

          unless test
            problem "A `test do` test block should be added"
            return
          end

          if test.body.nil?
            problem "`test do` should not be empty"
            return
          end

          return unless test.body.single_line? &&
                        test.body.source.to_s == "true"

          problem "`test do` should contain a real test"
        end
      end
    end
  end
end
