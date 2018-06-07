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
require "search"

module Homebrew
  module_function

  extend Search

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
      query = args.remaining.join(" ")
      string_or_regex = query_regexp(query)
      Descriptions.search(string_or_regex, :desc).print
    elsif args.remaining.first =~ HOMEBREW_TAP_FORMULA_REGEX
      query = args.remaining.first

      results = begin
        [Formulary.factory(query).name]
      rescue FormulaUnavailableError
        _, _, name = query.split("/", 3)
        remote_results = search_taps(name)
        [*remote_results[:formulae], *remote_results[:casks]].sort
      end

      puts Formatter.columns(results) unless results.empty?
    else
      query = args.remaining.join(" ")
      string_or_regex = query_regexp(query)
      local_results = search_formulae(string_or_regex)
      puts Formatter.columns(local_results.sort) unless local_results.empty?

      remote_results = search_taps(query)
      tap_results = [*remote_results[:formulae], *remote_results[:casks]].sort
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
end
