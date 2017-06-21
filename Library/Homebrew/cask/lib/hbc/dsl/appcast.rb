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
        result = SystemCommand.run("/usr/bin/curl", args: ["--compressed", "--location", "--user-agent", URL::FAKE_USER_AGENT, "--fail", @uri], print_stderr: false)

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
