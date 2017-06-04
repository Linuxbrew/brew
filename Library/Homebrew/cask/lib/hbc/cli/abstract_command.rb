require_relative "options"

module Hbc
  class CLI
    class AbstractCommand
      include Options

      option "--[no-]binaries", :binaries,      true
      option "--debug",         :debug,         false
      option "--verbose",       :verbose,       false
      option "--outdated",      :outdated_only, false

      def self.command_name
        @command_name ||= name.sub(/^.*:/, "").gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      def self.abstract?
        name.split("::").last.match?(/^Abstract[^a-z]/)
      end

      def self.visible
        true
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

      attr_accessor :args
      private :args=

      def initialize(*args)
        @args = process_arguments(*args)
      end
    end
  end
end
