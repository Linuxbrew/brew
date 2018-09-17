require_relative "options"
require "search"

module Cask
  class Cmd
    class AbstractCommand
      include Options
      include Homebrew::Search

      option "--[no-]binaries",   :binaries,      true
      option "--debug",           :debug,         false
      option "--verbose",         :verbose,       false
      option "--outdated",        :outdated_only, false
      option "--require-sha",     :require_sha,   false
      option "--[no-]quarantine", :quarantine,    true

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
        reason = [e.reason, *suggestion_message(e.token)].join(" ")
        raise e.class.new(e.token, reason)
      end

      def suggestion_message(cask_token)
        matches = search_casks(cask_token)

        if matches.one?
          "Did you mean “#{matches.first}”?"
        elsif !matches.empty?
          "Did you mean one of these?\n"
            .concat(Formatter.columns(matches.take(20)))
        end
      end
    end
  end
end
