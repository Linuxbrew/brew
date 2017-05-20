module Hbc
  class CLI
    class AbstractCommand
      def self.command_name
        @command_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      def self.abstract?
        !(name.split("::").last !~ /^Abstract[^a-z]/)
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

      def self.run(*args)
        new(*args).run
      end

      def initialize(*args)
        @args = args
      end
    end
  end
end
