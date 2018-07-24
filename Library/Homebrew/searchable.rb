module Searchable
  def search(string_or_regex, &block)
    case string_or_regex
    when Regexp
      search_regex(string_or_regex, &block)
    else
      search_string(string_or_regex.to_str, &block)
    end
  end

  private

  def simplify_string(string)
    string.downcase.gsub(/[^a-z\d]/i, "")
  end

  def search_regex(regex)
    select do |*args|
      args = yield(*args) if block_given?
      args = [*args].compact
      args.any? { |arg| arg.match?(regex) }
    end
  end

  def search_string(string)
    simplified_string = simplify_string(string)
    select do |*args|
      args = yield(*args) if block_given?
      args = [*args].compact
      args.any? { |arg| simplify_string(arg).include?(simplified_string) }
    end
  end
end
