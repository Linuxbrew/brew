#:  * `linkage` [`--test`] [`--reverse`] [`--rebuild`] <formula>:
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
#:
#:    If `--rebuild` is passed, flushes the `LinkageStore` cache for each
#:    'keg.name' and forces a check on the dylibs.

require "os/mac/linkage_checker"

module Homebrew
  module_function

  def linkage
    DatabaseCache.new(:linkage) do |database_cache|
      ARGV.kegs.each do |keg|
        ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1

        result = LinkageChecker.new(keg, database_cache, ARGV.include?("--rebuild"))

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
end
