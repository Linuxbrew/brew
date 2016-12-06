module Hbc
  class CLI
    class Search < Base
      def self.run(*arguments)
        render_results(*search(*arguments))
      end

      def self.extract_regexp(string)
        if string =~ %r{^/(.*)/$}
          Regexp.last_match[1]
        else
          false
        end
      end

      def self.search(*arguments)
        exact_match = nil
        partial_matches = []
        search_term = arguments.join(" ")
        search_regexp = extract_regexp arguments.first
        all_tokens = CLI.nice_listing(Hbc.all_tokens)
        if search_regexp
          search_term = arguments.first
          partial_matches = all_tokens.grep(/#{search_regexp}/i)
        else
          simplified_tokens = all_tokens.map { |t| t.sub(%r{^.*\/}, "").gsub(/[^a-z0-9]+/i, "") }
          simplified_search_term = search_term.sub(/\.rb$/i, "").gsub(/[^a-z0-9]+/i, "")
          exact_match = simplified_tokens.grep(/^#{simplified_search_term}$/i) { |t| all_tokens[simplified_tokens.index(t)] }.first
          partial_matches = simplified_tokens.grep(/#{simplified_search_term}/i) { |t| all_tokens[simplified_tokens.index(t)] }
          partial_matches.delete(exact_match)
        end
        [exact_match, partial_matches, search_term]
      end

      def self.render_results(exact_match, partial_matches, search_term)
        if !exact_match && partial_matches.empty?
          puts "No Cask found for \"#{search_term}\"."
          return
        end
        if exact_match
          ohai "Exact match"
          puts exact_match
        end

        return if partial_matches.empty?

        if extract_regexp search_term
          ohai "Regexp matches"
        else
          ohai "Partial matches"
        end
        puts Formatter.columns(partial_matches)
      end

      def self.help
        "searches all known Casks"
      end
    end
  end
end
