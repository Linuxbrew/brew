require "hbc/artifact/abstract_artifact"

module Hbc
  module Artifact
    class AbstractFlightBlock < AbstractArtifact
      def self.dsl_key
        super.to_s.sub(/_block$/, "").to_sym
      end

      def self.uninstall_dsl_key
        dsl_key.to_s.prepend("uninstall_").to_sym
      end

      def self.for_cask(cask)
        [dsl_key, uninstall_dsl_key].flat_map do |key|
          [*cask.artifacts[key]].map { |block| new(cask, key => block) }
        end
      end

      attr_reader :directives

      def initialize(cask, **directives)
        super(cask)
        @directives = directives
      end

      def install_phase(**)
        abstract_phase(self.class.dsl_key)
      end

      def uninstall_phase(**)
        abstract_phase(self.class.uninstall_dsl_key)
      end

      private

      def class_for_dsl_key(dsl_key)
        namespace = self.class.name.to_s.sub(/::.*::.*$/, "")
        self.class.const_get("#{namespace}::DSL::#{dsl_key.to_s.split("_").collect(&:capitalize).join}")
      end

      def abstract_phase(dsl_key)
        return if (block = directives[dsl_key]).nil?
        class_for_dsl_key(dsl_key).new(cask).instance_eval(&block)
      end

      def summarize
        directives.keys.map(&:to_s).join(", ")
      end
    end
  end
end
