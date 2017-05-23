require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      class Text < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          if !find_node_method_by_name(body_node, :plist_options) &&
             find_method_def(body_node, :plist)
            problem "Please set plist_options when using a formula-defined plist."
          end

          if depends_on?(body_node, "openssl") && depends_on?(body_node, "libressl")
            problem "Formulae should not depend on both OpenSSL and LibreSSL (even optionally)."
          end

          if method_called_ever?(body_node, :virtualenv_create) ||
             method_called_ever?(body_node, :virtualenv_install_with_resources)
            resource_calls = find_every_method_call_by_name(body_node, :resource)
            resource_calls.each do |m|
              if parameters_passed?(m, "setuptools")
                problem "Formulae using virtualenvs do not need a `setuptools` resource."
              end
            end
          end

          unless method_called_ever?(body_node, :go_resource)
            # processed_source.ast is passed instead of body_node because `require` would be outside body_node
            require_calls = find_every_method_call_by_name(processed_source.ast, :require)
            require_calls.each do |m|
              if parameters_passed?(m, "language/go")
                problem "require \"language/go\" is unnecessary unless using `go_resource`s"
              end
            end
          end

          factory_calls = find_every_method_call_by_name(body_node, :factory)
          unless factory_calls.nil?
            factory_calls.each do |m|
              if !m.children.empty? && m.children[0] && string_content(m.children[0]) == "Formula"
                offending_node(m)
                problem "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\""
              end
            end
          end

          xcodebuild_calls = find_every_method_call_by_name(body_node, :xcodebuild)
          unless xcodebuild_calls.nil?
            xcodebuild_calls.each do |m|
              params = parameters(m).map { |param| string_content(param) }
              if params.none? { |param| param.include?("SYMROOT=") } || params.empty?
                offending_node(m)
                problem 'xcodebuild should be passed an explicit "SYMROOT"'
              end
            end
          end

          system_calls = find_every_method_call_by_name(body_node, :system)
          return if system_calls.nil?
          system_calls.each do |m|
            if parameters_passed?(m, "go", "get")
              problem "Formulae should not use `go get`. If non-vendored resources are required use `go_resource`s."
            elsif parameters_passed?(m, "xcodebuild")
              problem %q(use "xcodebuild *args" instead of "system 'xcodebuild', *args")
            elsif parameters_passed?(m, "scons")
              problem "use \"scons *args\" instead of \"system 'scons', *args\""
            end
          end
        end
      end
    end
  end
end
