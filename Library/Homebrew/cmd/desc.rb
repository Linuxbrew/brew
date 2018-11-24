#:  * `desc` <formula>:
#:    Display <formula>'s name and one-line description.
#:
#:  * `desc` [`--search`|`--name`|`--description`] (<text>|`/`<text>`/`):
#:    Search both name and description (`--search` or `-s`), just the names
#:    (`--name` or `-n`), or just the descriptions (`--description` or `-d`) for
#:    <text>. If <text> is flanked by slashes, it is interpreted as a regular
#:    expression. Formula descriptions are cached; the cache is created on the
#:    first search, making that search slower than subsequent ones.

require "descriptions"
require "search"
require "description_cache_store"
require "cli_parser"

module Homebrew
  module_function

  extend Search

  def desc_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `desc` [<options>] (<text>|`/`<text>`/`|<formula>)

        Display <formula>'s name and one-line description.
        Formula descriptions are cached; the cache is created on the
        first search, making that search slower than subsequent ones.
      EOS
      flag "-s", "--search=",
       description: "Search both name and description for provided <text>. If <text> is flanked by "\
                    "slashes, it is interpreted as a regular expression."
      flag "-n", "--name=",
       description: "Search just the names for provided <text>. If <text> is flanked by slashes, it is "\
                    "interpreted as a regular expression."
      flag "-d", "--description=",
       description: "Search just the descriptions for provided <text>. If <text> is flanked by slashes, "\
                    "it is interpreted as a regular expression."
      switch :verbose
    end
  end

  def desc
    desc_args.parse

    search_type = []
    search_type << :either if args.search
    search_type << :name   if args.name
    search_type << :desc   if args.description
    if search_type.size > 1
      odie "Pick one, and only one, of -s/--search, -n/--name, or -d/--description."
    elsif search_type.present? && ARGV.named.empty?
      odie "You must provide a search term."
    end

    results = if search_type.empty?
      raise FormulaUnspecifiedError if ARGV.named.empty?

      desc = {}
      ARGV.formulae.each { |f| desc[f.full_name] = f.desc }
      Descriptions.new(desc)
    else
      arg = ARGV.named.join(" ")
      string_or_regex = query_regexp(arg)
      CacheStoreDatabase.use(:descriptions) do |db|
        cache_store = DescriptionCacheStore.new(db)
        Descriptions.search(string_or_regex, search_type.first, cache_store)
      end
    end

    results.print
  end
end
