#:  * `linkage` [`--test`] [`--reverse`] [`--cached`] <formula>:
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
#:    If `--cached` is passed, print the cached linkage values stored in
#:    HOMEBREW_CACHE, set from a previous `brew linkage` run

require "cache_store"
require "linkage_checker"
require "cli_parser"

module Homebrew
  module_function

  def linkage
    Homebrew::CLI::Parser.parse do
      switch "--test"
      switch "--reverse"
      switch "--cached"
      switch :verbose
      switch :debug
    end

    CacheStoreDatabase.use(:linkage) do |db|
      ARGV.kegs.each do |keg|
        ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1

        use_cache = args.cached? || ENV["HOMEBREW_LINKAGE_CACHE"]
        result = LinkageChecker.new(keg, use_cache: use_cache, cache_db: db)

        if args.test?
          result.display_test_output
          Homebrew.failed = true if result.broken_library_linkage?
        elsif args.reverse?
          result.display_reverse_output
        else
          result.display_normal_output
        end
      end
    end
  end
end
