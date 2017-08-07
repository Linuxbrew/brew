require 'FileUtils'
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
          # Commented-out cmake support from default template
          audit_comments do |comment|
            next unless comment.include?('# system "cmake')
            problem "Commented cmake call found"
          end

          # Comments from default template
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
            ].each do |template_comment|
              next unless comment.include?(template_comment)
              problem "Please remove default template comments"
              break
            end
          end

          audit_comments do |comment|
            # Commented-out depends_on
            next unless comment =~ /#\s*depends_on\s+(.+)\s*$/
            problem "Commented-out dep #{Regexp.last_match(1)}"
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

          [:rebuild, :version_scheme].each do |m|
            find_method_with_args(body_node, m, 0) do
              problem "'#{m} 0' should be removed"
            end
          end

          [:mac?, :linux?].each do |m|
            next unless formula_tap == "homebrew-core"
            find_instance_method_call(body_node, "OS", m) do |check|
              problem "Don't use #{check.source}; Homebrew/core only supports macOS"
            end
          end

          find_method_with_args(body_node, :fails_with, :llvm) do
            problem "'fails_with :llvm' is now a no-op so should be removed"
          end

          find_method_with_args(body_node, :system, /^(otool|install_name_tool|lipo)$/) do
            problem "Use ruby-macho instead of calling #{@offensive_node.source}"
          end
          #
          find_method_with_args(body_node, :system, /npm/, /install/) do |m|
            next if @formula_name =~ /^kibana(\@\d+(\.\d+)?)?$/
            problem "Use Language::Node for npm install args" unless languageNode?(m)
          end
          if find_method_def(body_node, :test)
            problem "Use new-style test definitions (test do)"
          end

          if find_method_def(body_node, :options)
            problem "Use new-style option definitions"
          end

          find_method_with_args(body_node, :skip_clean, :all) do
            problem "`skip_clean :all` is deprecated; brew no longer strips symbols\n" \
              "\tPass explicit paths to prevent Homebrew from removing empty folders."
          end

          find_instance_method_call(body_node, :build, :universal?) do
            problem "macOS has been 64-bit only so build.universal? is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :universal_binary) do
            problem "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :x11) do
            problem 'Use "depends_on :x11" instead of "ENV.x11"'
          end

          find_every_method_call_by_name(body_node, :assert).each do |m|
            if method_called?(m, :include?) && !method_called?(m, :!)
              problem "Use `assert_match` instead of `assert ...include?`"
            end
          end

          find_every_method_call_by_name(body_node, :depends_on).each do |m|
            next unless method_called?(m, :new)
            problem "`depends_on` can take requirement classes instead of instances"
          end

          os = [:leopard?, :snow_leopard?, :lion?, :mountain_lion?]
          os.each do |version|
            find_instance_method_call(body_node, :MacOS, version) do |m|
              problem "\"#{m.source}\" is deprecated, use a comparison to MacOS.version instead"
            end
          end

          dirPattern(body_node) do |m|
            next unless m =~ /\[("[^\*{},]+")\]/
            problem "Dir(#{Regexp.last_match(1)}) is unnecessary; just use #{Regexp.last_match(1)}"
          end

          fileUtils_methods= FileUtils.singleton_methods(false).map { |m| Regexp.escape(m) }.join "|"
          find_method_with_args(body_node, :system, /fileUtils_methods/) do |m|
            method = string_content(@offensive_node)
            problem "Use the `#{method}` Ruby method instead of `#{m.source}`"
          end


        end

        # This is Pattern Matching method for AST
        # Takes the AST node as argument and yields matching node if block given
        # Else returns boolean for the match
        def_node_search :languageNode?, <<-PATTERN
          (const (const nil :Language) :Node)
        PATTERN

        def_node_search :dirPattern, <<-PATTERN
          (send (const nil :Dir) :[] (str $_))
        PATTERN
      end
    end
  end
end

# Strict rules ported early
# find_method_with_args(@processed_source.ast, :require, "formula") do |m|
#   problem "#{m.source} is now unnecessary"
# end
