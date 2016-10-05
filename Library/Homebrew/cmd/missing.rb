#:  * `missing` [<formulae>]:
#:    Check the given <formulae> for missing dependencies. If no <formulae> are
#:    given, check all installed brews.

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

    hide = (ARGV.value("hide") || "").split(",")

    ff.each do |f|
      missing = f.missing_dependencies(hide: hide)
      next if missing.empty?

      print "#{f}: " if ff.size > 1
      puts missing.join(" ")
    end
  end
end
