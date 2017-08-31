module Hbc
  class CLI
    class Search < AbstractCommand
      def run
        if args.empty?
          puts Formatter.columns(CLI.nice_listing(Hbc.all_tokens))
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

      def self.search_remote(query)
        matches = begin
          GitHub.search_code(
            user: "caskroom",
            path: "Casks",
            filename: query,
            extension: "rb",
          )
        rescue GitHub::Error => error
          opoo "Error searching on GitHub: #{error}\n"
          []
        end
        matches.map do |match|
          tap = Tap.fetch(match["repository"]["full_name"])
          next if tap.installed?
          "#{tap.name}/#{File.basename(match["path"], ".rb")}"
        end.compact
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

        remote_matches = search_remote(search_term)

        [exact_match, partial_matches, remote_matches, search_term]
      end

      def self.render_results(exact_match, partial_matches, remote_matches, search_term)
        unless $stdout.tty?
          puts [*exact_match, *partial_matches, *remote_matches]
          return
        end

        if !exact_match && partial_matches.empty?
          puts "No Cask found for \"#{search_term}\"."
          return
        end
        if exact_match
          ohai "Exact Match"
          puts highlight_installed exact_match
        end

        unless partial_matches.empty?
          if extract_regexp search_term
            ohai "Regexp Matches"
          else
            ohai "Partial Matches"
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
