require "hbc/artifact/moved"

module Hbc
  module Artifact
    class Qlplugin < Moved
      def self.artifact_english_name
        "QuickLook Plugin"
      end

      def install_phase
        super
        reload_quicklook
      end

      def uninstall_phase
        super
        reload_quicklook
      end

      def reload_quicklook
        @command.run!("/usr/bin/qlmanage", args: ["-r"])
      end
    end
  end
end
