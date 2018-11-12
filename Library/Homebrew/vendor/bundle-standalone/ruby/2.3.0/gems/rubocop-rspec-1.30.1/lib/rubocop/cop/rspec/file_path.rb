# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that spec file paths are consistent with the test subject.
      #
      # Checks the path of the spec file and enforces that it reflects the
      # described class/module and its optionally called out method.
      #
      # With the configuration option `IgnoreMethods` the called out method will
      # be ignored when determining the enforced path.
      #
      # With the configuration option `CustomTransform` modules or classes can
      # be specified that should not as usual be transformed from CamelCase to
      # snake_case (e.g. 'RuboCop' => 'rubocop' ).
      #
      # @example
      #   # bad
      #   whatever_spec.rb         # describe MyClass
      #
      #   # bad
      #   my_class_spec.rb         # describe MyClass, '#method'
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_method_spec.rb  # describe MyClass, '#method'
      #
      #   # good
      #   my_class/method_spec.rb  # describe MyClass, '#method'
      #
      # @example when configuration is `IgnoreMethods: true`
      #   # bad
      #   whatever_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass
      #
      #   # good
      #   my_class_spec.rb         # describe MyClass, '#method'
      #
      class FilePath < Cop
        include RuboCop::RSpec::TopLevelDescribe

        MSG = 'Spec path should end with `%<suffix>s`.'.freeze

        def_node_search :const_described?,  '(send _ :describe (const ...) ...)'
        def_node_search :routing_metadata?, '(pair (sym :type) (sym :routing))'

        def on_top_level_describe(node, args)
          return unless const_described?(node) && single_top_level_describe?
          return if routing_spec?(args)

          glob = glob_for(args)

          return if filename_ends_with?(glob)

          add_offense(
            node,
            location: :expression,
            message: format(MSG, suffix: glob)
          )
        end

        private

        def routing_spec?(args)
          args.any?(&method(:routing_metadata?))
        end

        def glob_for((described_class, method_name))
          "#{expected_path(described_class)}#{name_glob(method_name)}*_spec.rb"
        end

        def name_glob(name)
          return unless name && name.str_type?

          "*#{name.str_content.gsub(/\W/, '')}" unless ignore_methods?
        end

        def expected_path(constant)
          File.join(
            constant.const_name.split('::').map do |name|
              custom_transform.fetch(name) { camel_to_snake_case(name) }
            end
          )
        end

        def camel_to_snake_case(string)
          string
            .gsub(/([^A-Z])([A-Z]+)/, '\1_\2')
            .gsub(/([A-Z])([A-Z][^A-Z\d]+)/, '\1_\2')
            .downcase
        end

        def custom_transform
          cop_config.fetch('CustomTransform', {})
        end

        def ignore_methods?
          cop_config['IgnoreMethods']
        end

        def filename_ends_with?(glob)
          File.fnmatch?("*#{glob}", processed_source.buffer.name)
        end

        def relevant_rubocop_rspec_file?(_file)
          true
        end
      end
    end
  end
end
