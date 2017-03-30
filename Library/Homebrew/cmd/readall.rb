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
      ruby_files = []
      scan_files = %W[
        #{HOMEBREW_LIBRARY}/*.rb
        #{HOMEBREW_LIBRARY}/Homebrew/**/*.rb
      ]
      Dir.glob(scan_files).each do |rb|
        next if rb.include?("/vendor/")
        next if rb.include?("/cask/")
        ruby_files << rb
      end

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
