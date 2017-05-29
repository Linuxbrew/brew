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

          if depends_on?("openssl") && depends_on?("libressl")
            problem "Formulae should not depend on both OpenSSL and LibreSSL (even optionally)."
          end

          if method_called_ever?(body_node, :virtualenv_create) ||
             method_called_ever?(body_node, :virtualenv_install_with_resources)
            find_method_with_args(body_node, :resource, "setuptools") do
              problem "Formulae using virtualenvs do not need a `setuptools` resource."
            end
          end

          unless method_called_ever?(body_node, :go_resource)
            # processed_source.ast is passed instead of body_node because `require` would be outside body_node
            find_method_with_args(processed_source.ast, :require, "language/go") do
              problem "require \"language/go\" is unnecessary unless using `go_resource`s"
            end
          end

          find_instance_method_call(body_node, "Formula", :factory) do
            problem "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\""
          end

          find_every_method_call_by_name(body_node, :xcodebuild).each do |m|
            next if parameters_passed?(m, /SYMROOT=/)
            problem 'xcodebuild should be passed an explicit "SYMROOT"'
          end

          find_method_with_args(body_node, :system, "xcodebuild") do
            problem %q(use "xcodebuild *args" instead of "system 'xcodebuild', *args")
          end

          find_method_with_args(body_node, :system, "scons") do
            problem "use \"scons *args\" instead of \"system 'scons', *args\""
          end

          find_method_with_args(body_node, :system, "go", "get") do
            problem "Formulae should not use `go get`. If non-vendored resources are required use `go_resource`s."
          end
        end
      end
    end
  end
end
