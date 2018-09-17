#:  * `formula` <formula>:
#:    Display the path where <formula> is located.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def formula
    Homebrew::CLI::Parser.parse do
      switch :debug
      switch :verbose
    end

    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each { |f| puts f.path }
  end
end
