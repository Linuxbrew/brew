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

module Homebrew
  module_function

  extend Search

  def desc
    search_type = []
    search_type << :either if ARGV.flag? "--search"
    search_type << :name   if ARGV.flag? "--name"
    search_type << :desc   if ARGV.flag? "--description"

    if search_type.empty?
      raise FormulaUnspecifiedError if ARGV.named.empty?

      desc = {}
      ARGV.formulae.each { |f| desc[f.full_name] = f.desc }
      results = Descriptions.new(desc)
      results.print
    elsif search_type.size > 1
      odie "Pick one, and only one, of -s/--search, -n/--name, or -d/--description."
    elsif !ARGV.named.empty?
      arg = ARGV.named.join(" ")
      string_or_regex = query_regexp(arg)
      results = Descriptions.search(string_or_regex, search_type.first)
      results.print
    else
      odie "You must provide a search term."
    end
  end
end
