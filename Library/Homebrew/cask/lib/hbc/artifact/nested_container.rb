require "hbc/artifact/abstract_artifact"

module Hbc
  module Artifact
    class NestedContainer < AbstractArtifact
      attr_reader :path

      def initialize(cask, path)
        super(cask)
        @path = cask.staged_path.join(path)
      end

      def install_phase(**options)
        extract(**options)
      end

      private

      def extract(command: nil, verbose: nil, **_)
        container = Container.for_path(path, command)

        unless container
          raise CaskError, "Aw dang, could not identify nested container at '#{source}'"
        end

        ohai "Extracting nested container #{path.relative_path_from(cask.staged_path)}"
        container.new(cask, path, command, verbose: verbose).extract
        FileUtils.remove_entry_secure(path)
      end
    end
  end
end
