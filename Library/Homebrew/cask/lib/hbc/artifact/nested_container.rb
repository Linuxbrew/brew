require "hbc/artifact/base"

module Hbc
  module Artifact
    class NestedContainer < Base
      def install_phase
        @cask.artifacts[:nested_container].each { |container| extract(container) }
      end

      def uninstall_phase
        # no need to take action; is removed after extraction
      end

      def extract(container_relative_path)
        source = @cask.staged_path.join(container_relative_path)
        container = Container.for_path(source, @command)

        unless container
          raise CaskError, "Aw dang, could not identify nested container at '#{source}'"
        end

        ohai "Extracting nested container #{source.basename}"
        container.new(@cask, source, @command).extract
        FileUtils.remove_entry_secure(source)
      end
    end
  end
end
