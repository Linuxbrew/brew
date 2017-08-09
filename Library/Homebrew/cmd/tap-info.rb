#:  * `tap-info`:
#:    Display a brief summary of all installed taps.
#:
#:  * `tap-info` (`--installed`|<taps>):
#:    Display detailed information about one or more <taps>.
#:
#:    Pass `--installed` to display information on all installed taps.
#:
#:  * `tap-info` `--json=`<version> (`--installed`|<taps>):
#:    Print a JSON representation of <taps>. Currently the only accepted value
#:    for <version> is `v1`.
#:
#:    Pass `--installed` to get information on installed taps.
#:
#:    See the docs for examples of using the JSON output:
#:    <https://docs.brew.sh/Querying-Brew.html>

require "tap"

module Homebrew
  module_function

  def tap_info
    if ARGV.include? "--installed"
      taps = Tap
    else
      taps = ARGV.named.map do |name|
        Tap.fetch(name)
      end
    end

    if ARGV.json == "v1"
      print_tap_json(taps)
    else
      print_tap_info(taps)
    end
  end

  def print_tap_info(taps)
    if taps.none?
      tap_count = 0
      formula_count = 0
      command_count = 0
      pinned_count = 0
      private_count = 0
      Tap.each do |tap|
        tap_count += 1
        formula_count += tap.formula_files.size
        command_count += tap.command_files.size
        pinned_count += 1 if tap.pinned?
        private_count += 1 if tap.private?
      end
      info = Formatter.pluralize(tap_count, "tap").to_s
      info += ", #{pinned_count} pinned"
      info += ", #{private_count} private"
      info += ", #{Formatter.pluralize(formula_count, "formula")}"
      info += ", #{Formatter.pluralize(command_count, "command")}"
      info += ", #{Tap::TAP_DIRECTORY.abv}" if Tap::TAP_DIRECTORY.directory?
      puts info
    else
      taps.each_with_index do |tap, i|
        puts unless i.zero?
        info = "#{tap}: "
        if tap.installed?
          info += tap.pinned? ? "pinned" : "unpinned"
          info += ", private" if tap.private?
          if (formula_count = tap.formula_files.size) > 0
            info += ", #{Formatter.pluralize(formula_count, "formula")}"
          end
          if (command_count = tap.command_files.size) > 0
            info += ", #{Formatter.pluralize(command_count, "command")}"
          end
          info += ", no formulae/commands" if (formula_count + command_count).zero?
          info += "\n#{tap.path} (#{tap.path.abv})"
          info += "\nFrom: #{tap.remote.nil? ? "N/A" : tap.remote}"
        else
          info += "Not installed"
        end
        puts info
      end
    end
  end

  def print_tap_json(taps)
    puts JSON.generate(taps.map(&:to_hash))
  end
end
