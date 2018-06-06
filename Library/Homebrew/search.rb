require "searchable"

module Homebrew
  module Search
    def query_regexp(query)
      if m = query.match(%r{^/(.*)/$})
        Regexp.new(m[1])
      else
        query
      end
    rescue RegexpError
      raise "#{query} is not a valid regex."
    end

    def search_taps(query, silent: false)
      results = { formulae: [], casks: [] }

      return results if ENV["HOMEBREW_NO_GITHUB_API"]

      unless silent
        # Use stderr to avoid breaking parsed output
        $stderr.puts Formatter.headline("Searching taps on GitHub...", color: :blue)
      end

      matches = begin
        GitHub.search_code(
          user: "Homebrew",
          path: ["Formula", "Casks", "."],
          filename: query,
          extension: "rb",
        )
      rescue GitHub::Error => error
        opoo "Error searching on GitHub: #{error}\n"
        return results
      end

      matches.each do |match|
        name = File.basename(match["path"], ".rb")
        tap = Tap.fetch(match["repository"]["full_name"])
        full_name = "#{tap.name}/#{name}"

        next if tap.installed? && !match["path"].start_with?("Casks/")

        if match["path"].start_with?("Casks/")
          results[:casks] = [*results[:casks], full_name].sort
        else
          results[:formulae] = [*results[:formulae], full_name].sort
        end
      end

      results
    end

    def search_formulae(string_or_regex)
      # Use stderr to avoid breaking parsed output
      $stderr.puts Formatter.headline("Searching local taps...", color: :blue)

      aliases = Formula.alias_full_names
      results = (Formula.full_names + aliases)
                .extend(Searchable)
                .search(string_or_regex)
                .sort

      results.map do |name|
        begin
          formula = Formulary.factory(name)
          canonical_name = formula.name
          canonical_full_name = formula.full_name
        rescue
          canonical_name = canonical_full_name = name
        end

        # Ignore aliases from results when the full name was also found
        next if aliases.include?(name) && results.include?(canonical_full_name)

        if (HOMEBREW_CELLAR/canonical_name).directory?
          pretty_installed(name)
        else
          name
        end
      end.compact
    end
  end
end
