#:  * `linkage` [`--test`] [`--reverse`]  <formula>:
#:    Checks the library links of an installed formula.
#:
#:    Only works on installed formulae. An error is raised if it is run on
#:    uninstalled formulae.
#:
#:    If `--test` is passed, only display missing libraries and exit with a
#:    non-zero exit code if any missing libraries were found.
#:
#:    If `--reverse` is passed, print the dylib followed by the binaries
#:    which link to it for each library the keg references.

require "os/mac/linkage_checker"

module Homebrew
  module_function

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
