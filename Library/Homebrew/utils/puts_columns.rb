require "utils/tty"

module Kernel
  def puts_columns(*objects, gap_size: 2)
    objects.flatten!

    if objects.empty? || (respond_to?(:tty?) && !tty?)
      puts(*objects)
      return
    end

    console_width = Tty.width

    object_lengths = objects.map { |obj| Tty.strip_ansi(obj.to_s).length }

    cols = (console_width + gap_size) / (object_lengths.max + gap_size)

    if cols < 2
      puts(*objects)
      return
    end

    rows = (objects.count + cols - 1) / cols
    cols = (objects.count + rows - 1) / rows # avoid empty trailing columns

    col_width = (console_width + gap_size) / cols - gap_size

    gap_string = "".rjust(gap_size)

    rows.times do |row_index|
      item_indices_for_row = row_index.step(objects.size - 1, rows).to_a

      first_n = item_indices_for_row[0...-1].map { |index|
        objects[index] + "".rjust(col_width - object_lengths[index])
      }

      # don't add trailing whitespace to last column
      last = objects.values_at(item_indices_for_row.last)

      puts (first_n + last).join(gap_string)
    end
  end
end
