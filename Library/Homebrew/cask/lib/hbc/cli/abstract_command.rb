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

      def self.warn_unavailable_with_suggestion(cask_token, e)
        exact_match, partial_matches = Search.search(cask_token)
        error_message = e.message
        if exact_match
          error_message.concat(" Did you mean:\n#{exact_match}")
        elsif !partial_matches.empty?
          error_message.concat(" Did you mean one of:\n")
                       .concat(Formatter.columns(partial_matches.take(20)))
        end
        onoe error_message
      end

      private

      def casks(alternative: -> { [] })
        return to_enum(:casks, alternative: alternative) unless block_given?

        count = 0

        casks = args.empty? ? alternative.call : args

        casks.each do |cask_or_token|
          begin
            yield cask_or_token.respond_to?(:token) ? cask_or_token : CaskLoader.load(cask_or_token)
            count += 1
          rescue CaskUnavailableError => e
            cask_token = cask_or_token
            self.class.warn_unavailable_with_suggestion cask_token, e
          rescue CaskError => e
            onoe e.message
          end
        end

        return :empty if casks.length.zero?
        (count == casks.length) ? :complete : :incomplete
      end
    end
  end
end
