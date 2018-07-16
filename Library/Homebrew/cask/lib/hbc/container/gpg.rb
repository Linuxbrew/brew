require "hbc/container/base"

module Hbc
  class Container
    class Gpg < Base
      def self.can_extract?(path:, magic_number:)
        path.extname == ".gpg"
      end

      def import_key
        if @cask.gpg.nil?
          raise CaskError, "Expected to find gpg public key in formula. Cask '#{@cask}' must add: 'gpg :embedded, key_id: [Public Key ID]' or 'gpg :embedded, key_url: [Public Key URL]'"
        end

        args = if @cask.gpg.key_id
          ["--recv-keys", @cask.gpg.key_id]
        elsif @cask.gpg.key_url
          ["--fetch-key", @cask.gpg.key_url.to_s]
        end

        @command.run!("gpg",
                      args: args,
                      env: { "PATH" => PATH.new(Formula["gnupg"].opt_bin, ENV["PATH"]) })
      end

      def extract_to_dir(unpack_dir, basename:)
        import_key

        Dir.mktmpdir do |tmp_unpack_dir|
          @command.run!("gpg",
                        args: ["--batch", "--yes", "--output", Pathname(tmp_unpack_dir).join(basename.basename(".gpg")), "--decrypt", path],
                        env: { "PATH" => PATH.new(Formula["gnupg"].opt_bin, ENV["PATH"]) })

          extract_nested_inside(tmp_unpack_dir, to: unpack_dir)
        end
      end

      def dependencies
        @dependencies ||= [Formula["gnupg"]]
      end
    end
  end
end
