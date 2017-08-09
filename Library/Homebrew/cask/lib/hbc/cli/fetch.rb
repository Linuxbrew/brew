module Hbc
  class CLI
    class Fetch < AbstractCommand
      option "--force", :force, false

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        raise CaskError, "Fetch incomplete." if fetch_casks == :incomplete
      end

      def fetch_casks
        casks.each do |cask|
          ohai "Downloading external files for Cask #{cask}"
          downloaded_path = Download.new(cask, force: force?).perform
          Verify.all(cask, downloaded_path)
          ohai "Success! Downloaded to -> #{downloaded_path}"
        end
      end

      def self.needs_init?
        true
      end

      def self.help
        "downloads remote application files to local cache"
      end
    end
  end
end
