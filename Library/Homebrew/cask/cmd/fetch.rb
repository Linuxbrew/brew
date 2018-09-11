require "cask/download"

module Cask
  class Cmd
    class Fetch < AbstractCommand
      option "--force", :force, false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        casks.each do |cask|
          Installer.print_caveats(cask)
          ohai "Downloading external files for Cask #{cask}"
          downloaded_path = Download.new(cask, force: force?, quarantine: quarantine?).perform
          Verify.all(cask, downloaded_path)
          ohai "Success! Downloaded to -> #{downloaded_path}"
        end
      end

      def self.help
        "downloads remote application files to local cache"
      end
    end
  end
end
