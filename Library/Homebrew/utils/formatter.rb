require "utils/tty"

module Formatter
  module_function

  def arrow(string, color: nil)
    prefix("==>", string, color)
  end

  def headline(string, color: nil)
    arrow("#{Tty.bold}#{string}#{Tty.reset}", color: color)
  end

  def identifier(string)
    "#{Tty.green}#{string}#{Tty.default}"
  end

  def option(string)
    "#{Tty.bold}#{string}#{Tty.reset}"
  end

  def success(string, label: nil)
    label(label, string, :green)
  end

  def warning(string, label: nil)
    label(label, string, :yellow)
  end

  def error(string, label: nil)
    label(label, string, :red)
  end

  def url(string)
    "#{Tty.underline}#{string}#{Tty.no_underline}"
  end

  def label(label, string, color)
    label = "#{label}:" unless label.nil?
    prefix(label, string, color)
  end
  private_class_method :label

  def prefix(prefix, string, color)
    if prefix.nil? && color.nil?
      string
    elsif prefix.nil?
      "#{Tty.send(color)}#{string}#{Tty.reset}"
    elsif color.nil?
      "#{prefix} #{string}"
    else
      "#{Tty.send(color)}#{prefix}#{Tty.reset} #{string}"
    end
  end
  private_class_method :prefix

  def columns(*objects, gap_size: 2)
    objects = objects.flatten.map(&:to_s)

    fallback = proc do
      return objects.join("\n").concat("\n")
    end

    fallback.call if objects.empty?
    fallback.call if respond_to?(:tty?) ? !tty? : !$stdout.tty?

    console_width = Tty.width
    object_lengths = objects.map { |obj| Tty.strip_ansi(obj).length }
    cols = (console_width + gap_size) / (object_lengths.max + gap_size)

    fallback.call if cols < 2

    rows = (objects.count + cols - 1) / cols
    cols = (objects.count + rows - 1) / rows # avoid empty trailing columns

    col_width = (console_width + gap_size) / cols - gap_size

    gap_string = "".rjust(gap_size)

    output = ""

    rows.times do |row_index|
      item_indices_for_row = row_index.step(objects.size - 1, rows).to_a

      first_n = item_indices_for_row[0...-1].map do |index|
        objects[index] + "".rjust(col_width - object_lengths[index])
      end

      # don't add trailing whitespace to last column
      last = objects.values_at(item_indices_for_row.last)

      output.concat((first_n + last).join(gap_string)).concat("\n")
    end

    output
  end

  def pluralize(count, singular, plural = nil, show_count: true)
    return (show_count ? "#{count} #{singular}" : singular.to_s) if count == 1

    *adjectives, noun = singular.to_s.split(" ")

    plural ||= {
      "formula" => "formulae",
    }.fetch(noun, "#{noun}s")

    words = adjectives.push(plural).join(" ")

    show_count ? "#{count} #{words}" : words
  end

  def comma_and(*items)
    # TODO: Remove when RuboCop 0.57.3 is released.
    # False positive has been fixed and merged, but is not yet in a
    # stable release: https://github.com/rubocop-hq/rubocop/pull/6038
    *items, last = items.map(&:to_s) # rubocop:disable Lint/ShadowedArgument
    return last if items.empty?

    "#{items.join(", ")} and #{last}"
  end
end
