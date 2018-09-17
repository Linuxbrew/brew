require "rubocops/extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for various miscellaneous Homebrew coding styles
      class Lines < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          [:automake, :ant, :autoconf, :emacs, :expat, :libtool, :mysql, :perl,
           :postgresql, :python, :python3, :rbenv, :ruby].each do |dependency|
            next unless depends_on?(dependency)

            problem ":#{dependency} is deprecated. Usage should be \"#{dependency}\"."
          end

          { apr: "apr-util", fortran: "gcc", gpg: "gnupg", hg: "mercurial",
            mpi: "open-mpi", python2: "python" }.each do |requirement, dependency|
            next unless depends_on?(requirement)

            problem ":#{requirement} is deprecated. Usage should be \"#{dependency}\"."
          end

          problem ":tex is deprecated." if depends_on?(:tex)
        end
      end

      class ClassInheritance < FormulaCop
        def audit_formula(_node, class_node, parent_class_node, _body_node)
          begin_pos = start_column(parent_class_node)
          end_pos = end_column(class_node)
          return unless begin_pos-end_pos != 3

          problem "Use a space in class inheritance: " \
                  "class #{@formula_name.capitalize} < #{class_name(parent_class_node)}"
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

      class AssertStatements < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          find_every_method_call_by_name(body_node, :assert).each do |method|
            if method_called_ever?(method, :include?) && !method_called_ever?(method, :!)
              problem "Use `assert_match` instead of `assert ...include?`"
            end

            if method_called_ever?(method, :exist?) && !method_called_ever?(method, :!)
              problem "Use `assert_predicate <path_to_file>, :exist?` instead of `#{method.source}`"
            end

            if method_called_ever?(method, :exist?) && method_called_ever?(method, :!)
              problem "Use `refute_predicate <path_to_file>, :exist?` instead of `#{method.source}`"
            end

            if method_called_ever?(method, :executable?) && !method_called_ever?(method, :!)
              problem "Use `assert_predicate <path_to_file>, :executable?` instead of `#{method.source}`"
            end
          end
        end
      end

      class OptionDeclarations < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          if find_method_def(body_node, :options)
            problem "Use new-style option definitions"
          end

          find_instance_method_call(body_node, :build, :without?) do |method|
            next unless unless_modifier?(method.parent)

            correct = method.source.gsub("out?", "?")
            problem "Use if #{correct} instead of unless #{method.source}"
          end

          find_instance_method_call(body_node, :build, :with?) do |method|
            next unless unless_modifier?(method.parent)

            correct = method.source.gsub("?", "out?")
            problem "Use if #{correct} instead of unless #{method.source}"
          end

          find_instance_method_call(body_node, :build, :with?) do |method|
            next unless expression_negated?(method)

            problem "Don't negate 'build.with?': use 'build.without?'"
          end

          find_instance_method_call(body_node, :build, :without?) do |method|
            next unless expression_negated?(method)

            problem "Don't negate 'build.without?': use 'build.with?'"
          end

          find_instance_method_call(body_node, :build, :without?) do |method|
            arg = parameters(method).first
            next unless match = regex_match_group(arg, /^-?-?without-(.*)/)

            problem "Don't duplicate 'without': " \
                    "Use `build.without? \"#{match[1]}\"` to check for \"--without-#{match[1]}\""
          end

          find_instance_method_call(body_node, :build, :with?) do |method|
            arg = parameters(method).first
            next unless match = regex_match_group(arg, /^-?-?with-(.*)/)

            problem "Don't duplicate 'with': Use `build.with? \"#{match[1]}\"` to check for \"--with-#{match[1]}\""
          end

          find_instance_method_call(body_node, :build, :include?) do |method|
            arg = parameters(method).first
            next unless match = regex_match_group(arg, /^with(out)?-(.*)/)

            problem "Use build.with#{match[1]}? \"#{match[2]}\" instead of " \
                    "build.include? 'with#{match[1]}-#{match[2]}'"
          end

          find_instance_method_call(body_node, :build, :include?) do |method|
            arg = parameters(method).first
            next unless match = regex_match_group(arg, /^\-\-(.*)$/)

            problem "Reference '#{match[1]}' without dashes"
          end
        end

        def unless_modifier?(node)
          return false unless node.if_type?

          node.modifier_form? && node.unless?
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
            next unless block_arg.source.size > 1

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

          find_instance_call(body_node, "ARGV") do |method_node|
            next if [:debug?, :verbose?, :value].index(method_node.method_name)

            problem "Use build instead of ARGV to check options"
          end

          find_instance_method_call(body_node, :man, :+) do |method|
            next unless match = regex_match_group(parameters(method).first, /^man[1-8]$/)

            problem "\"#{method.source}\" should be \"#{match[0]}\""
          end

          # Avoid hard-coding compilers
          find_every_method_call_by_name(body_node, :system).each do |method|
            param = parameters(method).first
            if match = regex_match_group(param, %r{^(/usr/bin/)?(gcc|llvm-gcc|clang)\s?})
              problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{match[2]}\""
            elsif match = regex_match_group(param, %r{^(/usr/bin/)?((g|llvm-g|clang)\+\+)\s?})
              problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{match[2]}\""
            end
          end

          find_instance_method_call(body_node, "ENV", :[]=) do |method|
            param = parameters(method)[1]
            if match = regex_match_group(param, %r{^(/usr/bin/)?(gcc|llvm-gcc|clang)\s?})
              problem "Use \"\#{ENV.cc}\" instead of hard-coding \"#{match[2]}\""
            elsif match = regex_match_group(param, %r{^(/usr/bin/)?((g|llvm-g|clang)\+\+)\s?})
              problem "Use \"\#{ENV.cxx}\" instead of hard-coding \"#{match[2]}\""
            end
          end

          # Prefer formula path shortcuts in strings
          formula_path_strings(body_node, :share) do |p|
            next unless match = regex_match_group(p, %r{^(/(man))/?})

            problem "\"\#{share}#{match[1]}\" should be \"\#{#{match[2]}}\""
          end

          formula_path_strings(body_node, :prefix) do |p|
            if match = regex_match_group(p, %r{^(/share/(info|man))$})
              problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[2]}}\""
            end
            if match = regex_match_group(p, %r{^((/share/man/)(man[1-8]))})
              problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[3]}}\""
            end
            if match = regex_match_group(p, %r{^(/(bin|include|libexec|lib|sbin|share|Frameworks))}i)
              problem "\"\#\{prefix}#{match[1]}\" should be \"\#{#{match[2].downcase}}\""
            end
          end

          find_every_method_call_by_name(body_node, :depends_on).each do |method|
            key, value = destructure_hash(parameters(method).first)
            next if key.nil? || value.nil?
            next unless match = regex_match_group(value, /^(lua|perl|python|ruby)(\d*)/)

            problem "#{match[1]} modules should be vendored rather than use deprecated #{method.source}`"
          end

          find_every_method_call_by_name(body_node, :system).each do |method|
            next unless match = regex_match_group(parameters(method).first, /^(env|export)(\s+)?/)

            problem "Use ENV instead of invoking '#{match[1]}' to modify the environment"
          end

          find_every_method_call_by_name(body_node, :depends_on).each do |method|
            param = parameters(method).first
            dep, option_child_nodes = hash_dep(param)
            next if dep.nil? || option_child_nodes.empty?

            option_child_nodes.each do |option|
              find_strings(option).each do |dependency|
                next unless match = regex_match_group(dependency, /(with(out)?-\w+|c\+\+11)/)

                problem "Dependency #{string_content(dep)} should not use option #{match[0]}"
              end
            end
          end

          find_instance_method_call(body_node, :version, :==) do |method|
            next unless parameters_passed?(method, "HEAD")

            problem "Use 'build.head?' instead of inspecting 'version'"
          end

          find_instance_method_call(body_node, "ARGV", :include?) do |method|
            param = parameters(method).first
            next unless match = regex_match_group(param, /^--(HEAD|devel)/)

            problem "Use \"if build.#{match[1].downcase}?\" instead"
          end

          find_const(body_node, "MACOS_VERSION") do
            problem "Use MacOS.version instead of MACOS_VERSION"
          end

          find_const(body_node, "MACOS_FULL_VERSION") do
            problem "Use MacOS.full_version instead of MACOS_FULL_VERSION"
          end

          conditional_dependencies(body_node) do |node, method, param, dep_node|
            dep = string_content(dep_node)
            if node.if?
              if (method == :include? && regex_match_group(param, /^with-#{dep}$/)) ||
                 (method == :with? && regex_match_group(param, /^#{dep}$/))
                offending_node(dep_node.parent)
                problem "Replace #{node.source} with #{dep_node.parent.source} => :optional"
              end
            elsif node.unless?
              if (method == :include? && regex_match_group(param, /^without-#{dep}$/)) ||
                 (method == :without? && regex_match_group(param, /^#{dep}$/))
                offending_node(dep_node.parent)
                problem "Replace #{node.source} with #{dep_node.parent.source} => :recommended"
              end
            end
          end

          find_method_with_args(body_node, :fails_with, :llvm) do
            problem "'fails_with :llvm' is now a no-op so should be removed"
          end

          find_method_with_args(body_node, :needs, :openmp) do
            problem "'needs :openmp' should be replaced with 'depends_on \"gcc\"'"
          end

          find_method_with_args(body_node, :system, /^(otool|install_name_tool|lipo)/) do
            next if @formula_name == "cctools"

            problem "Use ruby-macho instead of calling #{@offensive_node.source}"
          end

          find_every_method_call_by_name(body_node, :system).each do |method_node|
            # Skip Kibana: npm cache edge (see formula for more details)
            next if @formula_name =~ /^kibana(@\d[\d.]*)?$/

            first_param, second_param = parameters(method_node)
            next if !node_equals?(first_param, "npm") ||
                    !node_equals?(second_param, "install")

            offending_node(method_node)
            problem "Use Language::Node for npm install args" unless languageNodeModule?(method_node)
          end

          if find_method_def(body_node, :test)
            problem "Use new-style test definitions (test do)"
          end

          find_method_with_args(body_node, :skip_clean, :all) do
            problem "`skip_clean :all` is deprecated; brew no longer strips symbols. " \
                    "Pass explicit paths to prevent Homebrew from removing empty folders."
          end

          if find_method_def(@processed_source.ast)
            problem "Define method #{method_name(@offensive_node)} in the class body, not at the top-level"
          end

          find_instance_method_call(body_node, :build, :universal?) do
            next if @formula_name == "wine"

            problem "macOS has been 64-bit only since 10.6 so build.universal? is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :universal_binary) do
            next if @formula_name == "wine"

            problem "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated."
          end

          find_instance_method_call(body_node, "ENV", :x11) do
            problem 'Use "depends_on :x11" instead of "ENV.x11"'
          end

          find_every_method_call_by_name(body_node, :depends_on).each do |method|
            next unless method_called?(method, :new)

            problem "`depends_on` can take requirement classes instead of instances"
          end

          os = [:leopard?, :snow_leopard?, :lion?, :mountain_lion?]
          os.each do |version|
            find_instance_method_call(body_node, "MacOS", version) do |method|
              problem "\"#{method.source}\" is deprecated, use a comparison to MacOS.version instead"
            end
          end

          find_instance_method_call(body_node, "Dir", :[]) do |method|
            next unless parameters(method).size == 1

            path = parameters(method).first
            next unless path.str_type?
            next unless match = regex_match_group(path, /^[^\*{},]+$/)

            problem "Dir([\"#{string_content(path)}\"]) is unnecessary; just use \"#{match[0]}\""
          end

          fileutils_methods = Regexp.new(
            FileUtils.singleton_methods(false)
                     .map { |m| "(?-mix:^" + Regexp.escape(m) + "$)" }
                     .join("|"),
          )
          find_every_method_call_by_name(body_node, :system).each do |method|
            param = parameters(method).first
            next unless match = regex_match_group(param, fileutils_methods)

            problem "Use the `#{match}` Ruby method instead of `#{method.source}`"
          end
        end

        def modifier?(node)
          return false unless node.if_type?

          node.modifier_form?
        end

        def_node_search :conditional_dependencies, <<~EOS
          {$(if (send (send nil? :build) ${:include? :with? :without?} $(str _))
              (send nil? :depends_on $({str sym} _)) nil?)

           $(if (send (send nil? :build) ${:include? :with? :without?} $(str _)) nil?
              (send nil? :depends_on $({str sym} _)))}
        EOS

        def_node_matcher :hash_dep, <<~EOS
          (hash (pair $(str _) $...))
        EOS

        def_node_matcher :destructure_hash, <<~EOS
          (hash (pair $(str _) $(sym _)))
        EOS

        def_node_search :formula_path_strings, <<~EOS
          {(dstr (begin (send nil? %1)) $(str _ ))
           (dstr _ (begin (send nil? %1)) $(str _ ))}
        EOS

        # Node Pattern search for Language::Node
        def_node_search :languageNodeModule?, <<~EOS
          (const (const nil? :Language) :Node)
        EOS
      end
    end
  end
end
