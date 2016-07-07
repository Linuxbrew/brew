#
# Description: check linkage of installed keg
# Usage:
#   brew linkage <formulae>
#
# Only works on installed formulae. An error is raised if it is run on uninstalled
# formulae.
#
# Options:
#  --test      - testing version: only display broken libs; exit non-zero if any
#                breakage was found.
#  --reverse   - For each dylib the keg references, print the dylib followed by the
#                binaries which link to it.

require "os/mac/linkage_checker"

module Homebrew
  def linkage
    ARGV.kegs.each do |keg|
      ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1
      result = LinkageChecker.new(keg)
      if ARGV.include?("--test")
        result.display_test_output
        Homebrew.failed = true if result.broken_dylibs?
      elsif ARGV.include?("--reverse")
        result.display_reverse_output
      else
        result.display_normal_output
      end
    end
  end
end
