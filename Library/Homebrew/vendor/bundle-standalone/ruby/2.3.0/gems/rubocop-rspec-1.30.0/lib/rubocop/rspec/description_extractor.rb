module RuboCop
  module RSpec
    # Extracts cop descriptions from YARD docstrings
    class DescriptionExtractor
      def initialize(yardocs)
        @code_objects = yardocs.map(&CodeObject.public_method(:new))
      end

      def to_h
        code_objects
          .select(&:rspec_cop?)
          .map(&:configuration)
          .reduce(:merge)
      end

      private

      attr_reader :code_objects

      # Decorator of a YARD code object for working with documented rspec cops
      class CodeObject
        COP_CLASS_NAMES = %w[RuboCop::Cop RuboCop::Cop::RSpec::Cop].freeze
        RSPEC_NAMESPACE = 'RuboCop::Cop::RSpec'.freeze

        def initialize(yardoc)
          @yardoc = yardoc
        end

        # Test if the YARD code object documents a concrete rspec cop class
        #
        # @return [Boolean]
        def rspec_cop?
          class_documentation? &&
            rspec_cop_namespace? &&
            cop_subclass? &&
            !abstract?
        end

        # Configuration for the documented cop that would live in default.yml
        #
        # @return [Hash]
        def configuration
          { cop_name => { 'Description' => description } }
        end

        private

        def cop_name
          Object.const_get(documented_constant).cop_name
        end

        def description
          yardoc.docstring.split("\n\n").first.to_s
        end

        def class_documentation?
          yardoc.type.equal?(:class)
        end

        def rspec_cop_namespace?
          documented_constant.start_with?(RSPEC_NAMESPACE)
        end

        def documented_constant
          yardoc.to_s
        end

        def cop_subclass?
          # YARD superclass resolution is a bit flaky: All classes loaded before
          # RuboCop::Cop::WorkaroundCop are shown as having RuboCop::Cop as
          # superclass, while all the following classes are listed as having
          # RuboCop::Cop::RSpec::Cop as their superclass.
          COP_CLASS_NAMES.include?(yardoc.superclass.path)
        end

        def abstract?
          yardoc.tags.any? { |tag| tag.tag_name.eql?('abstract') }
        end

        attr_reader :yardoc
      end
    end
  end
end
