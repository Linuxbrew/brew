module Hbc
  class CLI
    class Base
      def self.command_name
        @command_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      def self.visible
        true
      end

      def self.cask_tokens_from(args)
        args.reject { |a| a.empty? || a.chars.first == "-" }
      end

      def self.help
        nil
      end

      def self.needs_init?
        false
      end
    end
  end
end
