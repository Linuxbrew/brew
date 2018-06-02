#:  * `search`, `-S`:
#:    Display all locally available formulae for brewing (including tapped ones).
#:    No online search is performed if called without arguments.
#:
#:  * `search` [`--desc`] (<text>|`/`<text>`/`):
#:    Perform a substring search of formula names for <text>. If <text> is
#:    surrounded with slashes, then it is interpreted as a regular expression.
#:    The search for <text> is extended online to some popular taps.
#:
#:    If `--desc` is passed, browse available packages matching <text> including a
#:    description for each.
#:
#:  * `search` (`--debian`|`--fedora`|`--fink`|`--macports`|`--opensuse`|`--ubuntu`) <text>:
#:    Search for <text> in the given package manager's list.

require "formula"
require "missing_formula"
require "descriptions"
require "cli_parser"

module Homebrew
  module_function

  PACKAGE_MANAGERS = {
    macports: ->(query) { "https://www.macports.org/ports.php?by=name&substr=#{query}" },
    fink:     ->(query) { "http://pdb.finkproject.org/pdb/browse.php?summary=#{query}" },
    debian:   ->(query) { "https://packages.debian.org/search?keywords=#{query}&searchon=names&suite=all&section=all" },
    opensuse: ->(query) { "https://software.opensuse.org/search?q=#{query}" },
    fedora:   ->(query) { "https://apps.fedoraproject.org/packages/s/#{query}" },
    ubuntu:   ->(query) { "https://packages.ubuntu.com/search?keywords=#{query}&searchon=names&suite=all&section=all" },
  }.freeze

  def search(argv = ARGV)
    CLI::Parser.parse(argv) do
      switch "--desc"

      package_manager_switches = PACKAGE_MANAGERS.keys.map { |name| "--#{name}" }

      package_manager_switches.each do |s|
        switch s
      end

      conflicts(*package_manager_switches)
    end

    if package_manager = PACKAGE_MANAGERS.detect { |name,| args[:"#{name}?"] }
      _, url = package_manager
      exec_browser url.call(URI.encode_www_form_component(args.remaining.join(" ")))
      return
    end

    if args.remaining.empty?
      puts Formatter.columns(Formula.full_names.sort)
    elsif args.desc?
      query = args.remaining.first
      regex = query_regexp(query)
      Descriptions.search(regex, :desc).print
    elsif args.remaining.first =~ HOMEBREW_TAP_FORMULA_REGEX
      query = args.remaining.first

      begin
        result = Formulary.factory(query).name
        results = Array(result)
      rescue FormulaUnavailableError
        _, _, name = query.split("/", 3)
        results = search_taps(name).flatten.sort
      end

      puts Formatter.columns(results) unless results.empty?
    else
      query = args.remaining.first
      regex = query_regexp(query)
      local_results = search_formulae(regex)
      puts Formatter.columns(local_results.sort) unless local_results.empty?

      tap_results = search_taps(query).flatten.sort
      puts Formatter.columns(tap_results) unless tap_results.empty?

      if $stdout.tty?
        count = local_results.length + tap_results.length

        ohai "Searching blacklisted, migrated and deleted formulae..."
        if reason = MissingFormula.reason(query, silent: true)
          if count.positive?
            puts
            puts "If you meant #{query.inspect} specifically:"
          end
          puts reason
        elsif count.zero?
          puts "No formula found for #{query.inspect}."
          GitHub.print_pull_requests_matching(query)
        end
      end
    end

    return unless $stdout.tty?
    return if args.remaining.empty?
    metacharacters = %w[\\ | ( ) [ ] { } ^ $ * + ?].freeze
    return unless metacharacters.any? do |char|
      args.remaining.any? do |arg|
        arg.include?(char) && !arg.start_with?("/")
      end
    end
    ohai <<~EOS
      Did you mean to perform a regular expression search?
      Surround your query with /slashes/ to search locally by regex.
    EOS
  end

  def query_regexp(query)
    if m = query.match(%r{^/(.*)/$})
      Regexp.new(m[1])
    else
      /.*#{Regexp.escape(query)}.*/i
    end
  rescue RegexpError
    raise "#{query} is not a valid regex."
  end

  def search_taps(query, silent: false)
    return [], [] if ENV["HOMEBREW_NO_GITHUB_API"]

    unless silent
      # Use stderr to avoid breaking parsed output
      $stderr.puts Formatter.headline("Searching taps on GitHub...", color: :blue)
    end

    matches = GitHub.search_code(
      user: "Homebrew",
      path: ["Formula", "Casks", "."],
      filename: query,
      extension: "rb",
    )

    matches.inject([[], []]) do |(formulae, casks), match|
      name = File.basename(match["path"], ".rb")
      tap = Tap.fetch(match["repository"]["full_name"])
      full_name = "#{tap.name}/#{name}"

      if tap.installed?
        [formulae, casks]
      elsif match["path"].start_with?("Casks/")
        [formulae, [*casks, full_name].sort]
      else
        [[*formulae, full_name].sort, casks]
      end
    end
  rescue GitHub::Error => error
    opoo "Error searching on GitHub: #{error}\n"
    [[], []]
  end

  def search_formulae(regex)
    # Use stderr to avoid breaking parsed output
    $stderr.puts Formatter.headline("Searching local taps...", color: :blue)

    aliases = Formula.alias_full_names
    results = (Formula.full_names + aliases).grep(regex).sort

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
