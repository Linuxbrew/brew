require "utils/tty"

module Formatter
  module_function

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

      first_n = item_indices_for_row[0...-1].map { |index|
        objects[index] + "".rjust(col_width - object_lengths[index])
      }

      # don't add trailing whitespace to last column
      last = objects.values_at(item_indices_for_row.last)

      output.concat((first_n + last).join(gap_string)).concat("\n")
    end

    output
  end
end
