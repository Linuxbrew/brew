module Hbc
  class CLI
    class Fetch < Base
      def self.run(*args)
        cask_tokens = cask_tokens_from(args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        force = args.include? "--force"

        cask_tokens.each do |cask_token|
          ohai "Downloading external files for Cask #{cask_token}"
          cask = Hbc.load(cask_token)
          downloaded_path = Download.new(cask, force: force).perform
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
