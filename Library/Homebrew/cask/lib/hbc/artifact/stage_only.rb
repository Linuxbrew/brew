require "hbc/artifact/base"

module Hbc
  module Artifact
    class StageOnly < Base
      def self.artifact_dsl_key
        :stage_only
      end
    end
  end
end
