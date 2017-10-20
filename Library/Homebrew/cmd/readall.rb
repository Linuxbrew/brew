#: @hide_from_man_page
#:  * `readall` [tap]:
#:    Import all formulae in a tap (defaults to core tap).
#:
#:    This can be useful for debugging issues across all formulae
#:    when making significant changes to `formula.rb`,
#:    or to determine if any current formulae have Ruby issues.

require "readall"

module Homebrew
  module_function

  def readall
    if ARGV.include?("--syntax")
      scan_files = "#{HOMEBREW_LIBRARY_PATH}/**/*.rb"
      ruby_files = Dir.glob(scan_files).reject { |file| file =~ %r{/(vendor|cask)/} }

      Homebrew.failed = true unless Readall.valid_ruby_syntax?(ruby_files)
    end

    options = { aliases: ARGV.include?("--aliases") }
    taps = if ARGV.named.empty?
      Tap
    else
      [Tap.fetch(ARGV.named.first)]
    end
    taps.each do |tap|
      Homebrew.failed = true unless Readall.valid_tap?(tap, options)
    end
  end
end
