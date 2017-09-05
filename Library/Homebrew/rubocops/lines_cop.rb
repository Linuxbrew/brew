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
          problem "Use a space in class inheritance: class #{class_name(class_node)} < #{class_name(parent_class_node)}"
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

      class Miscellaneous < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          # FileUtils is included in Formula
          # encfs modifies a file with this name, so check for some leading characters
          find_instance_method_call(body_node, "FileUtils", nil) do |method_node|
            problem "Don't need 'FileUtils.' before #{method_node.method_name}"
          end

          # Check for long inreplace block vars
          find_all_blocks(body_node, :inreplace) do |node|
            block_arg = node.arguments.children.first
            next unless block_arg.source.size>1
            problem "\"inreplace <filenames> do |s|\" is preferred over \"|#{block_arg.source}|\"."
          end

          [:rebuild, :version_scheme].each do |method_name|
            find_method_with_args(body_node, method_name, 0) do
              problem "'#{method_name} 0' should be removed"
            end
          end

          [:mac?, :linux?].each do |method_name|
            next unless formula_tap == "homebrew-core"
            find_instance_method_call(body_node, "OS", method_name) do |check|
              problem "Don't use #{check.source}; Homebrew/core only supports macOS"
            end
          end

          find_method_with_args(body_node, :fails_with, :llvm) do
            problem "'fails_with :llvm' is now a no-op so should be removed"
          end

          find_method_with_args(body_node, :system, /^(otool|install_name_tool|lipo)$/) do
            next if @formula_name == "cctools"
            problem "Use ruby-macho instead of calling #{@offensive_node.source}"
          end

          find_every_method_call_by_name(body_node, :system).each do |method_node|
            # Skip Kibana: npm cache edge (see formula for more details)
            next if @formula_name =~ /^kibana(\@\d+(\.\d+)?)?$/
            first_param, second_param = parameters(method_node)
            next if !node_equals?(first_param, "npm") ||
                    !node_equals?(second_param, "install")
            offending_node(method_node)
            problem "Use Language::Node for npm install args" unless languageNodeModule?(method_node)
          end

          if find_method_def(body_node, :test)
            problem "Use new-style test definitions (test do)"
          end

          if find_method_def(body_node, :options)
            problem "Use new-style option definitions"
          end

          find_method_with_args(body_node, :skip_clean, :all) do
            problem <<-EOS.undent.chomp
              `skip_clean :all` is deprecated; brew no longer strips symbols
                      Pass explicit paths to prevent Homebrew from removing empty folders.
            EOS
          end

          find_instance_method_call(body_node, :build, :universal?) do
            next if @formula_name == "wine"
            problem "macOS has been 64-bit only since 10.6 so build.universal? is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :universal_binary) do
            problem "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :x11) do
            problem 'Use "depends_on :x11" instead of "ENV.x11"'
          end
        end

        # Node Pattern search for Language::Node
        def_node_search :languageNodeModule?, <<-EOS.undent
          (const (const nil :Language) :Node)
        EOS
      end
    end
  end
end
