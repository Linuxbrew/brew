#:  * `linkage` [`--test`] [`--reverse`] [<formulae>]:
#:    Check the library links for kegs of installed formulae.
#:    Raises an error if run on uninstalled formulae.
#:
#:    If `--test` is passed, only display missing libraries and exit with a
#:    non-zero status if any missing libraries are found.
#:
#:    If `--reverse` is passed, for every library that a keg references,
#:    print its dylib path followed by the binaries that link to it.
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
        `linkage` [<options>] [<formulae>]

        Check the library links for kegs of installed formulae.
        Raises an error if run on uninstalled formulae.
      EOS
      switch "--test",
        description: "Display only missing libraries and exit with a non-zero status if any missing "\
                     "libraries are found."
      switch "--reverse",
        description: "For every library that a keg references, print its dylib path followed by the "\
                     "binaries that link to it."
      switch "--cached",
        description: "Print the cached linkage values stored in `HOMEBREW_CACHE`, set by a previous "\
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
