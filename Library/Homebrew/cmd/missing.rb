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

    Diagnostic.missing_deps(ff) do |name, missing|
      print "#{name}: " if ff.size > 1
      puts (missing * " ").to_s
    end
  end
end
