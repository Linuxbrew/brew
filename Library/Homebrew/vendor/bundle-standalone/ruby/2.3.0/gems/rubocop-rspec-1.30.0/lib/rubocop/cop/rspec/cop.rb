# frozen_string_literal: true

module RuboCop
  module Cop # rubocop:disable Style/Documentation
    WorkaroundCop = Cop.dup

    # Clone of the the normal RuboCop::Cop::Cop class so we can rewrite
    # the inherited method without breaking functionality
    class WorkaroundCop
      # Remove the Cop.inherited method to be a noop. Our RSpec::Cop
      # class will invoke the inherited hook instead
      class << self
        undef inherited
        def inherited(*) end
      end

      # Special case `Module#<` so that the rspec support rubocop exports
      # is compatible with our subclass
      def self.<(other)
        other.equal?(RuboCop::Cop::Cop) || super
      end
    end
    private_constant(:WorkaroundCop)

    module RSpec
      # @abstract parent class to rspec cops
      #
      # The criteria for whether rubocop-rspec analyzes a certain ruby file
      # is configured via `AllCops/RSpec`. For example, if you want to
      # customize your project to scan all files within a `test/` directory
      # then you could add this to your configuration:
      #
      # @example configuring analyzed paths
      #
      #   AllCops:
      #     RSpec:
      #       Patterns:
      #       - '_test.rb$'
      #       - '(?:^|/)test/'
      class Cop < WorkaroundCop
        include RuboCop::RSpec::Language
        include RuboCop::RSpec::Language::NodePattern

        DEFAULT_CONFIGURATION =
          RuboCop::RSpec::CONFIG.fetch('AllCops').fetch('RSpec')

        DEFAULT_PATTERN_RE = Regexp.union(
          DEFAULT_CONFIGURATION.fetch('Patterns')
                               .map(&Regexp.public_method(:new))
        )

        # Invoke the original inherited hook so our cops are recognized
        def self.inherited(subclass)
          RuboCop::Cop::Cop.inherited(subclass)
        end

        def relevant_file?(file)
          relevant_rubocop_rspec_file?(file) && super
        end

        private

        def relevant_rubocop_rspec_file?(file)
          rspec_pattern =~ file
        end

        def rspec_pattern
          if rspec_pattern_config?
            Regexp.union(rspec_pattern_config.map(&Regexp.public_method(:new)))
          else
            DEFAULT_PATTERN_RE
          end
        end

        def all_cops_config
          config
            .for_all_cops
        end

        def rspec_pattern_config?
          return unless all_cops_config.key?('RSpec')

          all_cops_config.fetch('RSpec').key?('Patterns')
        end

        def rspec_pattern_config
          all_cops_config
            .fetch('RSpec', DEFAULT_CONFIGURATION)
            .fetch('Patterns')
        end
      end
    end
  end
end
