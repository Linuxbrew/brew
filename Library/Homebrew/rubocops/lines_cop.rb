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

          # [:debug?, :verbose?, :value].each do |m|
          #   find_instance_method_call(body_node, :ARGV, m) do
          #     problem "Use build instead of ARGV to check options"
          #   end
          # end
          #
          # find_instance_method_call(body_node, :man, :+) do |m|
          #   next unless match = regex_match_group(parameters(m).first, %r{man[1-8]})
          #   problem "\"#{m.source}\" should be \"#{match[1]}\""
          # end
          #
          # # Avoid hard-coding compilers
          # find_every_method_call_by_name(body_node, :system).each do |m|
          #   param = parameters(m).first
          #   if match = regex_match_group(param, %r{(/usr/bin/)?(gcc|llvm-gcc|clang)\s?})
          #     problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{match[3]}\""
          #   elsif match = regex_match_group(param, %r{(/usr/bin/)?((g|llvm-g|clang)\+\+)\s?})
          #     problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{match[3]}\""
          #   end
          # end
          #
          # find_instance_method_call(body_node, :ENV, :[]=) do |m|
          #   param = parameters(m)[1]
          #   if match = regex_match_group(param, %r{(/usr/bin/)?(gcc|llvm-gcc|clang)\s?})
          #     problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{match[3]}\""
          #   elsif match = regex_match_group(param, %r{(/usr/bin/)?((g|llvm-g|clang)\+\+)\s?})
          #     problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{match[3]}\""
          #   end
          # end
          #
          # # Prefer formula path shortcuts in strings
          # formula_path_strings(body_node, :prefix) do |p|
          #   next unless match = regex_match_group(p, %r{(/(man))[/'"]})
          #   problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[3]}}\""
          # end
          #
          # formula_path_strings(body_node, :share) do |p|
          #   if match = regex_match_group(p, %r{/(bin|include|libexec|lib|sbin|share|Frameworks)}i)
          #     problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[1].downcase}}\""
          #   end
          #   if match = regex_match_group(p, %r{((/share/man/|\#\{man\}/)(man[1-8]))})
          #     problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[3]}}\""
          #   end
          #   if match = regex_match_group(p, %r{(/share/(info|man))})
          #     problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[2]}}\""
          #   end
          # end
          #
          # find_every_method_call_by_name(body_node, :depends_on) do |m|
          #   key, value = destructure_hash(paramters(m).first)
          #   next unless key.str_type?
          #   next unless match = regex_match_group(value, %r{(lua|perl|python|ruby)(\d*)})
          #   problem "#{match[1]} modules should be vendored rather than use deprecated #{m.source}`"
          # end
          #
          # find_every_method_call_by_name(body_node, :system).each do |m|
          #   next unless match = regex_match_group(parameters(m).first, %r{(env|export)(\s+)?})
          #   problem "Use ENV instead of invoking '#{match[1]}' to modify the environment"
          # end
          #
          # find_every_method_call_by_name(body_node, :depends_on).each do |m|
          #   next unless modifier?(m)
          #   dep, option = hash_dep(m)
          #   next if dep.nil? || option.nil?
          #   problem "Dependency #{string_content(dep)} should not use option #{string_content(option)}"
          # end
          #
          # find_instance_method_call(body_node, :version, :==) do |m|
          #   next unless parameters_passed?(m, "HEAD")
          #   problem "Use 'build.head?' instead of inspecting 'version'"
          # end
          #
          # find_instance_method_call(body_node, :ENV, :fortran) do
          #   next if depends_on?(:fortran)
          #   problem "Use `depends_on :fortran` instead of `ENV.fortran`"
          # end
          #
          # find_instance_method_call(body_node, :ARGV, :include?) do |m|
          #   param = parameters(m).first
          #   next unless match = regex_match_group(param, %r{--(HEAD|devel)})
          #   problem "Use \"if build.#{match[1].downcase}?\" instead"
          # end
          #
          # find_const(body_node, :MACOS_VERSION) do
          #   problem "Use MacOS.version instead of MACOS_VERSION"
          # end
          #
          # find_const(body_node, :MACOS_FULL_VERSION) do
          #   problem "Use MacOS.full_version instead of MACOS_FULL_VERSION"
          # end
          #
          # dependency(body_node) do |m|
          #   # handle symbols and shit: WIP
          #   next unless modifier?(m.parent)
          #   dep = parameters(m).first
          #   condition = m.parent.condition
          #   if (condition.if? && condition.method_name == :include? && parameters_passed(condition, /with-#{string_content(dep)}$/))||
          #       (condition.if? && condition.method_name == :with? && parameters_passed?(condition, /#{string_content(dep)}$/))
          #     problem "Replace #{m.parent.source} with #{dep.source} => :optional"
          #   end
          #   if (condition.unless? && condition.method_name == :include? && parameters_passed?(condition, /without-#{string_content(dep)}$/))||
          #       (condition.unless? && condition.method_name == :without? && parameters_passed?(condition, /#{string_content(dep)}$/))
          #     problem "Replace #{m.parent.source} with #{dep.source} => :recommended"
          #   end
          # end
          #
          # find_every_method_call_by_name(body_node, :depends_on).each do |m|
          #   next unless modifier?(m.parent)
          #   dep = parameters(m).first
          #   next if dep.hash_type?
          #   condition = m.parent.node_parts
          # end

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
            find_instance_method_call(body_node, "MacOS", version) do |m|
              problem "\"#{m.source}\" is deprecated, use a comparison to MacOS.version instead"
            end
          end

          find_instance_method_call(body_node, "Dir", :[]) do |m|
            path = parameters(m).first
            next if !path.str_type?
            next unless match = regex_match_group(path, /^[^\*{},]+$/)
            problem "Dir([\"#{string_content(path)}\"]) is unnecessary; just use \"#{match[0]}\""
          end


          fileUtils_methods= Regexp.new(FileUtils.singleton_methods(false).map { |m| Regexp.escape(m) }.join "|")
          find_every_method_call_by_name(body_node, :system).each do |m|
            param = parameters(m).first
            next unless match = regex_match_group(param, fileUtils_methods)
            problem "Use the `#{match}` Ruby method instead of `#{m.source}`"
          end

          if find_method_def(@processed_source.ast)
            problem "Define method #{method_name(@offensive_node)} in the class body, not at the top-level"
          end

          find_instance_method_call(body_node, :build, :without?) do |m|
            next unless unless_modifier?(m.parent)
            correct = m.source.gsub("out?", "?")
            problem "Use if #{correct} instead of unless #{m.source}"
          end

          find_instance_method_call(body_node, :build, :with?) do |m|
            next unless unless_modifier?(m.parent)
            correct = m.source.gsub("?", "out?")
            problem "Use if #{correct} instead of unless #{m.source}"
          end

          find_instance_method_call(body_node, :build, :with?) do |m|
            next unless negated?(m.parent)
            problem "Don't negate 'build.with?': use 'build.without?'"
          end

          find_instance_method_call(body_node, :build, :without?) do |m|
            next unless negated?(m.parent)
            problem "Don't negate 'build.without?': use 'build.with?'"
          end

          # find_instance_method_call(body_node, :build, :without?) do |m|
          #   arg = parameters(m).first
          #   next unless match = regex_match_group(arg, %r{-?-?without-(.*)})
          #   problem "Don't duplicate 'without': Use `build.without? \"#{match[1]}\"` to check for \"--without-#{match[1]}\""
          # end
          #
          # find_instance_method_call(body_node, :build, :with?) do |m|
          #   arg = parameters(m).first
          #   next unless match = regex_match_group(arg, %r{-?-?with-(.*)})
          #   problem "Don't duplicate 'with': Use `build.with? \"#{match[1]}\"` to check for \"--with-#{match[1]}\""
          # end
          #
          # find_instance_method_call(body_node, :build, :include?) do |m|
          #   arg = parameters(m).first
          #   next unless match = regex_match_group(arg, %r{with(out)?-(.*)})
          #   problem "Use build.with#{match[1]}? \"#{match[2]}\" instead of build.include? 'with#{match[1]}-#{match[2]}'"
          # end
          #
          # find_instance_method_call(body_node, :build, :include?) do |m|
          #   arg = parameters(m).first
          #   next unless match = regex_match_group(arg, %r{\-\-(.*)})
          #   problem "Reference '#{match[1]}' without dashes"
          # end

        end

        def unless_modifier?(node)
          return false unless node.if_type?
          node.modifier_form? && node.unless?
        end

        def modifier?(node)
          node.modifier_form?
        end

        def_node_search :condition, <<-EOS.undent
          (send (send nil :build) $_ $({str sym} _))
        EOS

        def_node_search :dependency, <<-EOS.undent
          (send nil :depends_on ({str sym} _))
        EOS

        # Match depends_on with hash as argument
        def_node_search :hash_dep, <<-EOS.undent
          {$(hash (pair $(str _) $(str _)))
           $(hash (pair $(str _) (array $(str _) ...)))}
        EOS

        def_node_search :destructure_hash, <<-EOS.undent
          (hash (pair $_ $_))
        EOS

        def_node_matcher :formula_path_strings, <<-EOS.undent
          (dstr (begin (send nil %1)) $(str _ ))
        EOS

        def_node_matcher :negation?, '(send ... :!)'
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
