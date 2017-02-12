#:  * `formula` <formula>:
#:    Display the path where <formula> is

require "formula"

module Homebrew
  module_function

  def formula
    raise FormulaUnspecifiedError if ARGV.named.empty?
    ARGV.resolved_formulae.each { |f| puts f.path }
  end
end
