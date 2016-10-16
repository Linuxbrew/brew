#:  * `desc` <formula>:
#:    Display <formula>'s name and one-line description.
#:
#:  * `desc` [`-s`|`-n`|`-d`] <pattern>:
#:    Search both name and description (`-s`), just the names (`-n`), or just  the
#:    descriptions (`-d`) for `<pattern>`. `<pattern>` is by default interpreted
#:    as a literal string; if flanked by slashes, it is instead interpreted as a
#:    regular expression. Formula descriptions are cached; the cache is created on
#:    the first search, making that search slower than subsequent ones.

require "descriptions"
require "cmd/search"

module Homebrew
  module_function

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
    elsif arg = ARGV.named.first
      regex = Homebrew.query_regexp(arg)
      results = Descriptions.search(regex, search_type.first)
      results.print
    else
      odie "You must provide a search term."
    end
  end
end
