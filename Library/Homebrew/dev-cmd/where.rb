#:  * `where` <formulae>:
#:    echo location of the specified <formulae> to stdout

require "formula"

module Homebrew
  module_function

  def where
    raise FormulaUnspecifiedError if ARGV.named.empty?
    ARGV.resolved_formulae.each do |f|
      puts "#{f.path}\n"
    end
  end
end
