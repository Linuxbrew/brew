require "search"

module Hbc
  class CLI
    class Search < AbstractCommand
      extend Homebrew::Search

      def run
        if args.empty?
          puts Formatter.columns(CLI.nice_listing(Cask.map(&:qualified_token)))
        else
          results = self.class.search(*args)
          self.class.render_results(*results)
        end
      end

      def self.search(*arguments)
        query = arguments.join(" ")
        string_or_regex = query_regexp(query)
        local_results = search_casks(string_or_regex)

        remote_matches = search_taps(query, silent: true)[:casks]

        [local_results, remote_matches, query]
      end

      def self.render_results(partial_matches, remote_matches, search_term)
        unless $stdout.tty?
          puts [*partial_matches, *remote_matches]
          return
        end

        if partial_matches.empty? && remote_matches.empty?
          puts "No Cask found for \"#{search_term}\"."
          return
        end

        unless partial_matches.empty?
          ohai "Matches"
          puts Formatter.columns(partial_matches)
        end

        return if remote_matches.empty?
        ohai "Remote Matches"
        puts Formatter.columns(remote_matches)
      end

      def self.help
        "searches all known Casks"
      end
    end
  end
end
