require "hbc/system_command"

module Hbc
  class DSL
    class Appcast
      attr_reader :parameters, :checkpoint

      def initialize(uri, parameters = {})
        @parameters     = parameters
        @uri            = UnderscoreSupportingURI.parse(uri)
        @checkpoint     = @parameters[:checkpoint]
      end

      def calculate_checkpoint
        curl_executable, *args = curl_args(
          "--compressed", "--location", "--fail", @uri,
          user_agent: :fake
        )
        result = SystemCommand.run(curl_executable, args: args, print_stderr: false)

        checkpoint = if result.success?
          processed_appcast_text = result.stdout.gsub(%r{<pubDate>[^<]*</pubDate>}m, "")
          Digest::SHA2.hexdigest(processed_appcast_text)
        end

        {
          checkpoint: checkpoint,
          command_result: result,
        }
      end

      def to_yaml
        [@uri, @parameters].to_yaml
      end

      def to_s
        @uri.to_s
      end
    end
  end
end
