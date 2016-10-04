require "hbc/artifact/base"

module Hbc
  module Artifact
    class StageOnly < Base
      def self.artifact_dsl_key
        :stage_only
      end

      def install_phase
        # do nothing
      end

      def uninstall_phase
        # do nothing
      end
    end
  end
end
