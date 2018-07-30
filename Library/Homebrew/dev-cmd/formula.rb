#:  * `formula` <formula>:
#:    Display the path where <formula> is located.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def formula_args
    Homebrew::CLI::Parser.new do
      switch :debug
      switch :verbose
    end
  end

  def formula
    formula_args.parse

    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each { |f| puts f.path }
  end
end
