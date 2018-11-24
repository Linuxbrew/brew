#:  * `missing` [`--hide=`<hidden>] [<formulae>]:
#:    Check the given <formulae> for missing dependencies. If no <formulae> are
#:    given, check all installed brews.
#:
#:    If `--hide=`<hidden> is passed, act as if none of <hidden> are installed.
#:    <hidden> should be a comma-separated list of formulae.
#:
#:    `missing` exits with a non-zero status if any formulae are missing dependencies.

require "formula"
require "tab"
require "diagnostic"
require "cli_parser"

module Homebrew
  module_function

  def missing_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `missing` [<options>] [<formulae>]

        Check the given <formulae> for missing dependencies. If no <formulae> are
        given, check all installed brews.

        `missing` exits with a non-zero status if any formulae are missing dependencies.
      EOS
      comma_array "--hide",
        description: "Act as if none of the provided <hidden> are installed. <hidden> should be "\
                     "comma-separated list of formulae."
      switch :verbose
      switch :debug
    end
  end

  def missing
    missing_args.parse
    return unless HOMEBREW_CELLAR.exist?

    ff = if ARGV.named.empty?
      Formula.installed.sort
    else
      ARGV.resolved_formulae.sort
    end

    ff.each do |f|
      missing = f.missing_dependencies(hide: args.hide)
      next if missing.empty?

      Homebrew.failed = true
      print "#{f}: " if ff.size > 1
      puts missing.join(" ")
    end
  end
end
