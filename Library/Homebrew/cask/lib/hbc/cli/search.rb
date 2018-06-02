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

      def self.extract_regexp(string)
        if string =~ %r{^/(.*)/$}
          Regexp.last_match[1]
        else
          false
        end
      end

      def self.search(*arguments)
        partial_matches = []
        search_term = arguments.join(" ")
        search_regexp = extract_regexp arguments.first
        all_tokens = CLI.nice_listing(Cask.map(&:qualified_token))
        if search_regexp
          search_term = arguments.first
          partial_matches = all_tokens.grep(/#{search_regexp}/i)
        else
          simplified_tokens = all_tokens.map { |t| t.sub(%r{^.*\/}, "").gsub(/[^a-z0-9]+/i, "") }
          simplified_search_term = search_term.sub(/\.rb$/i, "").gsub(/[^a-z0-9]+/i, "")
          partial_matches = simplified_tokens.grep(/#{simplified_search_term}/i) { |t| all_tokens[simplified_tokens.index(t)] }
        end

        _, remote_matches = search_taps(search_term, silent: true)

        [partial_matches, remote_matches, search_term]
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
          if extract_regexp search_term
            ohai "Regexp Matches"
          else
            ohai "Matches"
          end
          puts Formatter.columns(partial_matches.map(&method(:highlight_installed)))
        end

        return if remote_matches.empty?
        ohai "Remote Matches"
        puts Formatter.columns(remote_matches.map(&method(:highlight_installed)))
      end

      def self.highlight_installed(token)
        return token unless Cask.new(token).installed?
        pretty_installed token
      end

      def self.help
        "searches all known Casks"
      end
    end
  end
end
