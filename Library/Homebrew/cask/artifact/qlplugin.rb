require "cask/artifact/moved"

module Cask
  module Artifact
    class Qlplugin < Moved
      def self.english_name
        "QuickLook Plugin"
      end

      def install_phase(**options)
        super(**options)
        reload_quicklook(**options)
      end

      def uninstall_phase(**options)
        super(**options)
        reload_quicklook(**options)
      end

      private

      def reload_quicklook(command: nil, **_)
        command.run!("/usr/bin/qlmanage", args: ["-r"])
      end
    end
  end
end
