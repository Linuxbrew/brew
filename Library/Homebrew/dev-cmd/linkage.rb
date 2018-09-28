#:  * `linkage` [`--test`] [`--reverse`] [<formulae>]:
#:    Checks the library links of installed formulae.
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
#:    If <formulae> are given, check linkage for only the specified brews.

require "cache_store"
require "linkage_checker"
require "cli_parser"

module Homebrew
  module_function

  def linkage_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `linkage` [<options>] <formula>:

        Checks the library links of an installed formula.

        Only works on installed formulae. An error is raised if it is run on
        uninstalled formulae.
      EOS
      switch "--test",
        description: "Display only missing libraries and exit with a non-zero exit code if any missing "\
                     "libraries were found."
      switch "--reverse",
        description: "Print the dylib followed by the binaries which link to it for each library the keg "\
                     "references."
      switch "--cached",
        description: "Print the cached linkage values stored in HOMEBREW_CACHE, set from a previous "\
                     "`brew linkage` run."
      switch :verbose
      switch :debug
    end
  end

  def linkage
    linkage_args.parse

    CacheStoreDatabase.use(:linkage) do |db|
      kegs = if ARGV.kegs.empty?
        Formula.installed.map(&:opt_or_installed_prefix_keg).reject(&:nil?)
      else
        ARGV.kegs
      end
      kegs.each do |keg|
        ohai "Checking #{keg.name} linkage" if kegs.size > 1

        result = LinkageChecker.new(keg, cache_db: db)

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
