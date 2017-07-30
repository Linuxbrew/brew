require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for various miscellaneous Homebrew coding styles
      class Lines < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          [:automake, :autoconf, :libtool].each do |dependency|
            next unless depends_on?(dependency)
            problem ":#{dependency} is deprecated. Usage should be \"#{dependency}\""
          end

          problem ':apr is deprecated. Usage should be "apr-util"' if depends_on?(:apr)
          problem ":tex is deprecated" if depends_on?(:tex)
        end
      end

      class ClassInheritance < FormulaCop
        def audit_formula(_node, class_node, parent_class_node, _body_node)
          begin_pos = start_column(parent_class_node)
          end_pos = end_column(class_node)
          return unless begin_pos-end_pos != 3
          problem "Use a space in class inheritance: class #{@formula_name} < #{class_name(parent_class_node)}"
        end
      end

      class Comments < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          audit_comments do |comment|
            [
              "# PLEASE REMOVE",
              "# Documentation:",
              "# if this fails, try separate make/make install steps",
              "# The URL of the archive",
              "## Naming --",
              "# if your formula requires any X11/XQuartz components",
              "# if your formula fails when building in parallel",
              "# Remove unrecognized options if warned by configure",
              '# system "cmake',
            ].each do |template_comment|
              next unless comment.include?(template_comment)
              problem "Please remove default template comments"
              break
            end
          end

          audit_comments do |comment|
            # Commented-out depends_on
            next unless comment =~ /#\s*depends_on\s+(.+)\s*$/
            problem "Commented-out dependency #{Regexp.last_match(1)}"
          end
        end
      end
    end
  end
end
