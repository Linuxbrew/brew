require 'yaml'

module RuboCop
  module RSpec
    # Builds a YAML config file from two config hashes
    class ConfigFormatter
      NAMESPACES = /^(RSpec|Capybara|FactoryBot|Rails)/.freeze
      STYLE_GUIDE_BASE_URL = 'http://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/'.freeze

      def initialize(config, descriptions)
        @config       = config
        @descriptions = descriptions
      end

      def dump
        YAML.dump(unified_config).gsub(NAMESPACES, "\n\\1")
      end

      private

      def unified_config
        cops.each_with_object(config.dup) do |cop, unified|
          unified[cop] = config.fetch(cop)
            .merge(descriptions.fetch(cop))
            .merge('StyleGuide' => STYLE_GUIDE_BASE_URL + cop.sub('RSpec/', ''))
        end
      end

      def cops
        (descriptions.keys | config.keys).grep(NAMESPACES)
      end

      attr_reader :config, :descriptions
    end
  end
end
