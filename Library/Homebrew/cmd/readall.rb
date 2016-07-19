# `brew readall` tries to import all formulae one-by-one.
# This can be useful for debugging issues across all formulae
# when making significant changes to formula.rb,
# or to determine if any current formulae have Ruby issues

require "readall"

module Homebrew
  def readall
    if ARGV.include?("--syntax")
      ruby_files = []
      scan_files = %W[
        #{HOMEBREW_LIBRARY}/*.rb
        #{HOMEBREW_LIBRARY}/Homebrew/**/*.rb
      ]
      Dir.glob(scan_files).each do |rb|
        next if rb.include?("/vendor/")
        ruby_files << rb
      end

      Homebrew.failed = true unless Readall.valid_ruby_syntax?(ruby_files)
    end

    options = { :aliases => ARGV.include?("--aliases") }
    taps = if ARGV.named.any?
      [Tap.fetch(ARGV.named.first)]
    else
      Tap
    end
    taps.each do |tap|
      Homebrew.failed = true unless Readall.valid_tap?(tap, options)
    end
  end
end
