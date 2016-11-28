#:  * `missing` [`--hide=`<hidden>] [<formulae>]:
#:    Check the given <formulae> for missing dependencies. If no <formulae> are
#:    given, check all installed brews.
#:
#:    If `--hide=`<hidden> is passed, act as if none of <hidden> are installed.
#:    <hidden> should be a comma-separated list of formulae.

require "formula"
require "tab"
require "diagnostic"

module Homebrew
  module_function

  def missing
    return unless HOMEBREW_CELLAR.exist?

    ff = if ARGV.named.empty?
      Formula.installed
    else
      ARGV.resolved_formulae
    end

    ff.each do |f|
      missing = f.missing_dependencies(hide: ARGV.values("hide"))
      next if missing.empty?

      print "#{f}: " if ff.size > 1
      puts missing.join(" ")
    end
  end
end
