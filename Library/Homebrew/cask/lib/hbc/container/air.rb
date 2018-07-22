require "hbc/container/base"

module Hbc
  class Container
    class Air < Base
      def self.can_extract?(path:, magic_number:)
        path.extname == ".air"
      end

      def extract_to_dir(unpack_dir, basename:, verbose:)
        @command.run!(
          "/Applications/Utilities/Adobe AIR Application Installer.app/Contents/MacOS/Adobe AIR Application Installer",
          args: ["-silent", "-location", unpack_dir, path],
        )
      end

      def dependencies
        @dependencies ||= [CaskLoader.load("adobe-air")]
      end
    end
  end
end
