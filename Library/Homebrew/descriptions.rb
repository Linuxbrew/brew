require "formula"
require "formula_versions"
require "search"
require "searchable"

class Descriptions
  extend Homebrew::Search

  # Given a regex, find all formulae whose specified fields contain a match.
  def self.search(string_or_regex, field, cache_store)
    cache_store.populate_if_empty!

    results = case field
    when :name
      cache_store.search(string_or_regex) { |name, _| name }
    when :desc
      cache_store.search(string_or_regex) { |_, desc| desc }
    when :either
      cache_store.search(string_or_regex)
    end

    new(results)
  end

  # Create an actual instance.
  def initialize(descriptions)
    @descriptions = descriptions
  end

  # Take search results -- a hash mapping formula names to descriptions -- and
  # print them.
  def print
    blank = Formatter.warning("[no description]")
    @descriptions.keys.sort.each do |full_name|
      short_name = short_names[full_name]
      printed_name = if short_name_counts[short_name] == 1
        short_name
      else
        full_name
      end
      description = @descriptions[full_name] || blank
      puts "#{Tty.bold}#{printed_name}:#{Tty.reset} #{description}"
    end
  end

  private

  def short_names
    @short_names ||= Hash[@descriptions.keys.map { |k| [k, k.split("/").last] }]
  end

  def short_name_counts
    @short_name_counts ||=
      short_names.values
                 .each_with_object(Hash.new(0)) do |name, counts|
        counts[name] += 1
      end
  end
end
