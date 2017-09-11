require_relative "options"

module Hbc
  class CLI
    class AbstractCommand
      include Options

      option "--[no-]binaries", :binaries,      true
      option "--debug",         :debug,         false
      option "--verbose",       :verbose,       false
      option "--outdated",      :outdated_only, false
      option "--require-sha",   :require_sha, false

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

      private

      def casks(alternative: -> { [] })
        return @casks if defined?(@casks)
        casks = args.empty? ? alternative.call : args
        @casks = casks.map { |cask| CaskLoader.load(cask) }
      rescue CaskUnavailableError => e
        reason = [e.reason, suggestion_message(e.token)].join(" ")
        raise e.class.new(e.token, reason)
      end

      def suggestion_message(cask_token)
        exact_match, partial_matches = Search.search(cask_token)

        if exact_match.nil? && partial_matches.count == 1
          exact_match = partial_matches.first
        end

        if exact_match
          "Did you mean “#{exact_match}”?"
        elsif !partial_matches.empty?
          "Did you mean one of these?\n"
            .concat(Formatter.columns(partial_matches.take(20)))
        else
          ""
        end
      end
    end
  end
end
